import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.textures.DataTexture;
import three.constants.Constants;
import three.math.Matrix4;
import three.objects.Mesh;
import three.math.ColorManagement;
import three.math.Box3;
import three.math.Sphere;
import three.math.Frustum;
import three.math.Vector3;

@:native("MultiDrawRenderList")
private extern class MultiDrawRenderListData {
	var index:Int;
	var pool:Array<{ start:Int, count:Int, z:Float }>;
	var list:Array<{ start:Int, count:Int, z:Float }>;
}

private class MultiDrawRenderList {

	var data:MultiDrawRenderListData;

	public function new() {
		data = {
			index: 0,
			pool: [],
			list: []
		};
	}

	public function push(drawRange:{ start:Int, count:Int }, z:Float):Void {
		var pool = data.pool;
		var list = data.list;
		if (data.index >= pool.length) {
			pool.push({
				start: -1,
				count: -1,
				z: -1
			});
		}

		var item = pool[data.index];
		list.push(item);
		data.index++;

		item.start = drawRange.start;
		item.count = drawRange.count;
		item.z = z;
	}

	public function reset():Void {
		data.list = [];
		data.index = 0;
	}

}

class BatchedMesh extends Mesh {

	private static var ID_ATTR_NAME:String = 'batchId';
	private static var _matrix:Matrix4 = new Matrix4();
	private static var _invMatrixWorld:Matrix4 = new Matrix4();
	private static var _identityMatrix:Matrix4 = new Matrix4();
	private static var _projScreenMatrix:Matrix4 = new Matrix4();
	private static var _frustum:Frustum = new Frustum();
	private static var _box:Box3 = new Box3();
	private static var _sphere:Sphere = new Sphere();
	private static var _vector:Vector3 = new Vector3();
	private static var _renderList:MultiDrawRenderList = new MultiDrawRenderList();
	private static var _mesh:Mesh = new Mesh();
	private static var _batchIntersects:Array<{
		object:Dynamic,
		batchId:Int
	}> = [];

	public var isBatchedMesh:Bool = true;
	public var perObjectFrustumCulled:Bool;
	public var sortObjects:Bool;
	public var customSort:Dynamic;

	private var _drawRanges:Array<{ start:Int, count:Int }>;
	private var _reservedRanges:Array<{
		vertexStart:Int,
		vertexCount:Int,
		indexStart:Int,
		indexCount:Int
	}>;

	private var _visibility:Array<Bool>;
	private var _active:Array<Bool>;
	private var _bounds:Array<{
		boxInitialized:Bool,
		box:Box3,
		sphereInitialized:Bool,
		sphere:Sphere
	}>;

	private var _maxGeometryCount:Int;
	private var _maxVertexCount:Int;
	private var _maxIndexCount:Int;

	private var _geometryInitialized:Bool = false;
	private var _geometryCount:Int = 0;
	private var _multiDrawCounts:Array<Int>;
	private var _multiDrawStarts:Array<Int>;
	private var _multiDrawCount:Int = 0;
	private var _multiDrawInstances:Array<Int> = null;
	private var _visibilityChanged:Bool = true;

	private var _matricesTexture:DataTexture = null;
	private var _colorsTexture:DataTexture = null;

	public function new(maxGeometryCount:Int, maxVertexCount:Int, ?maxIndexCount:Int, ?material:Dynamic) {
		super(new BufferGeometry(), material);

		if (maxIndexCount == null) maxIndexCount = maxVertexCount * 2;

		this.perObjectFrustumCulled = true;
		this.sortObjects = true;

		this._drawRanges = [];
		this._reservedRanges = [];

		this._visibility = [];
		this._active = [];
		this._bounds = [];

		this._maxGeometryCount = maxGeometryCount;
		this._maxVertexCount = maxVertexCount;
		this._maxIndexCount = maxIndexCount;

		this._multiDrawCounts = [];
		this._multiDrawStarts = [];

		_initMatricesTexture();
	}

	public function get maxGeometryCount():Int {
		return this._maxGeometryCount;
	}

	private function _initMatricesTexture():Void {
		var size:Int = Math.ceil(Math.sqrt(this._maxGeometryCount * 4) / 4) * 4;
		size = Math.max(size, 4);

		var matricesArray:Array<Float> = [];
		matricesArray[size * size * 4 - 1] = 0; // initialize to correct size
		var matricesTexture:DataTexture = new DataTexture(matricesArray, size, size, Constants.RGBAFormat, Constants.FloatType);

		this._matricesTexture = matricesTexture;
	}

	private function _initColorsTexture():Void {
		var size:Int = Math.ceil(Math.sqrt(this._maxGeometryCount));

		var colorsArray:Array<Float> = [];
		colorsArray[size * size * 4 - 1] = 0; // initialize to correct size
		var colorsTexture = new DataTexture(colorsArray, size, size, Constants.RGBAFormat, Constants.FloatType);
		colorsTexture.colorSpace = ColorManagement.workingColorSpace;

		this._colorsTexture = colorsTexture;
	}

	private function _initializeGeometry(reference:BufferGeometry):Void {
		var geometry:BufferGeometry = this.geometry;
		var maxVertexCount:Int = this._maxVertexCount;
		var maxGeometryCount:Int = this._maxGeometryCount;
		var maxIndexCount:Int = this._maxIndexCount;
		if (!this._geometryInitialized) {
			for (attributeName in reference.attributes.keys()) {
				var srcAttribute:BufferAttribute = reference.getAttribute(attributeName);
				var array = srcAttribute.array;
				var itemSize = srcAttribute.itemSize;
				var normalized = srcAttribute.normalized;

				var dstArray:Array<Float> = switch (array) {
					case Array<Float>(_): [];
					case Array<Int>(_): throw 'Int array not supported';
					default: throw 'Unsupported array type';
				}
				dstArray[maxVertexCount * itemSize - 1] = 0;
				var dstAttribute:BufferAttribute = new BufferAttribute(dstArray, itemSize, normalized);

				geometry.setAttribute(attributeName, dstAttribute);
			}

			if (reference.getIndex() != null) {
				var indexArray = maxVertexCount > 65536 ? new Uint32Array(maxIndexCount) : new Uint16Array(maxIndexCount);
				geometry.setIndex(new BufferAttribute(indexArray.buffer, 1));
			}

			var idArray:Dynamic = maxGeometryCount > 65536 ? new Uint32Array(maxVertexCount) : new Uint16Array(maxVertexCount);
			geometry.setAttribute(ID_ATTR_NAME, new BufferAttribute(idArray.buffer, 1));

			this._geometryInitialized = true;
		}
	}

	private function _validateGeometry(geometry:BufferGeometry):Void {
		if (geometry.getAttribute(ID_ATTR_NAME) != null) {
			throw new Error('BatchedMesh: Geometry cannot use attribute "${ID_ATTR_NAME}"');
		}

		var batchGeometry:BufferGeometry = this.geometry;
		if (geometry.getIndex() != null != batchGeometry.getIndex() != null) {
			throw new Error('BatchedMesh: All geometries must consistently have "index".');
		}

		for (attributeName in batchGeometry.attributes.keys()) {
			if (attributeName == ID_ATTR_NAME) {
				continue;
			}

			if (!geometry.attributes.exists(attributeName)) {
				throw new Error('BatchedMesh: Added geometry missing "${attributeName}". All geometries must have consistent attributes.');
			}

			var srcAttribute:BufferAttribute = geometry.getAttribute(attributeName);
			var dstAttribute:BufferAttribute = batchGeometry.getAttribute(attributeName);
			if (srcAttribute.itemSize != dstAttribute.itemSize || srcAttribute.normalized != dstAttribute.normalized) {
				throw new Error('BatchedMesh: All attributes must have a consistent itemSize and normalized value.');
			}
		}
	}

	public function setCustomSort(func:Dynamic):BatchedMesh {
		this.customSort = func;
		return this;
	}

	override public function computeBoundingBox():Void {
		if (this.boundingBox == null) {
			this.boundingBox = new Box3();
		}

		var geometryCount:Int = this._geometryCount;
		var boundingBox:Box3 = this.boundingBox;
		var active:Array<Bool> = this._active;

		boundingBox.makeEmpty();
		for (i in 0...geometryCount) {
			if (!active[i])
				continue;

			this.getMatrixAt(i, _matrix);
			this.getBoundingBoxAt(i, _box).applyMatrix4(_matrix);
			boundingBox.union(_box);
		}
	}

	override public function computeBoundingSphere():Void {
		if (this.boundingSphere == null) {
			this.boundingSphere = new Sphere();
		}

		var geometryCount:Int = this._geometryCount;
		var boundingSphere:Sphere = this.boundingSphere;
		var active:Array<Bool> = this._active;

		boundingSphere.makeEmpty();
		for (i in 0...geometryCount) {
			if (!active[i])
				continue;

			this.getMatrixAt(i, _matrix);
			this.getBoundingSphereAt(i, _sphere).applyMatrix4(_matrix);
			boundingSphere.union(_sphere);
		}
	}

	public function addGeometry(geometry:BufferGeometry, ?vertexCount:Int, ?indexCount:Int):Int {
		if (vertexCount == null)
			vertexCount = -1;
		if (indexCount == null)
			indexCount = -1;
		this._initializeGeometry(geometry);

		this._validateGeometry(geometry);

		if (this._geometryCount >= this._maxGeometryCount) {
			throw new Error('BatchedMesh: Maximum geometry count reached.');
		}

		var reservedRange = {
			vertexStart: -1,
			vertexCount: -1,
			indexStart: -1,
			indexCount: -1
		};

		var lastRange = this._reservedRanges.length > 0 ? this._reservedRanges[this._reservedRanges.length - 1] : null;
		var reservedRanges = this._reservedRanges;
		var drawRanges = this._drawRanges;
		var bounds = this._bounds;

		if (vertexCount == -1) {
			reservedRange.vertexCount = Std.int(geometry.getAttribute('position').count);
		} else {
			reservedRange.vertexCount = vertexCount;
		}

		if (lastRange == null) {
			reservedRange.vertexStart = 0;
		} else {
			reservedRange.vertexStart = lastRange.vertexStart + lastRange.vertexCount;
		}

		var index = geometry.getIndex();
		var hasIndex:Bool = index != null;
		if (hasIndex) {
			if (indexCount == -1) {
				reservedRange.indexCount = Std.int(index.count);
			} else {
				reservedRange.indexCount = indexCount;
			}

			if (lastRange == null) {
				reservedRange.indexStart = 0;
			} else {
				reservedRange.indexStart = lastRange.indexStart + lastRange.indexCount;
			}
		}

		if (reservedRange.indexStart != -1 && reservedRange.indexStart + reservedRange.indexCount > this._maxIndexCount
			|| reservedRange.vertexStart + reservedRange.vertexCount > this._maxVertexCount) {
			throw new Error('BatchedMesh: Reserved space request exceeds the maximum buffer size.');
		}

		var visibility = this._visibility;
		var active = this._active;
		var matricesTexture = this._matricesTexture;
		var matricesArray = matricesTexture.image.data;

		visibility.push(true);
		active.push(true);

		var geometryId:Int = this._geometryCount;
		this._geometryCount++;

		_identityMatrix.toArray(matricesArray, geometryId * 16);
		matricesTexture.needsUpdate = true;

		reservedRanges.push(reservedRange);
		drawRanges.push({
			start: hasIndex ? reservedRange.indexStart : reservedRange.vertexStart,
			count: -1
		});
		bounds.push({
			boxInitialized: false,
			box: new Box3(),

			sphereInitialized: false,
			sphere: new Sphere()
		});

		var idAttribute = this.geometry.getAttribute(ID_ATTR_NAME);
		for (i in 0...reservedRange.vertexCount) {
			idAttribute.setX(reservedRange.vertexStart + i, geometryId);
		}

		idAttribute.needsUpdate = true;

		this.setGeometryAt(geometryId, geometry);

		return geometryId;
	}

	public function setGeometryAt(id:Int, geometry:BufferGeometry):Int {
		if (id >= this._geometryCount) {
			throw new Error('BatchedMesh: Maximum geometry count reached.');
		}

		this._validateGeometry(geometry);

		var batchGeometry:BufferGeometry = this.geometry;
		var hasIndex:Bool = batchGeometry.getIndex() != null;
		var dstIndex = batchGeometry.getIndex();
		var srcIndex = geometry.getIndex();
		var reservedRange = this._reservedRanges[id];
		if (hasIndex && srcIndex.count > reservedRange.indexCount
			|| geometry.attributes.get('position').count > reservedRange.vertexCount) {
			throw new Error('BatchedMesh: Reserved space not large enough for provided geometry.');
		}

		var vertexStart:Int = reservedRange.vertexStart;
		var vertexCount:Int = reservedRange.vertexCount;
		for (attributeName in batchGeometry.attributes.keys()) {
			if (attributeName == ID_ATTR_NAME) {
				continue;
			}

			var srcAttribute:BufferAttribute = geometry.getAttribute(attributeName);
			var dstAttribute:BufferAttribute = batchGeometry.getAttribute(attributeName);
			copyAttributeData(srcAttribute, dstAttribute, vertexStart);

			var itemSize:Int = srcAttribute.itemSize;
			for (i in srcAttribute.count...vertexCount) {
				var index:Int = vertexStart + i;
				for (c in 0...itemSize) {
					dstAttribute.setComponent(index, c, 0);
				}
			}

			dstAttribute.needsUpdate = true;
		}

		if (hasIndex) {
			var indexStart:Int = reservedRange.indexStart;

			for (i in 0...srcIndex.count) {
				dstIndex.setX(indexStart + i, vertexStart + Std.int(srcIndex.getX(i)));
			}

			for (i in srcIndex.count...reservedRange.indexCount) {
				dstIndex.setX(indexStart + i, vertexStart);
			}

			dstIndex.needsUpdate = true;
		}

		var bound = this._bounds[id];
		if (geometry.boundingBox != null) {
			bound.box.copy(geometry.boundingBox);
			bound.boxInitialized = true;
		} else {
			bound.boxInitialized = false;
		}

		if (geometry.boundingSphere != null) {
			bound.sphere.copy(geometry.boundingSphere);
			bound.sphereInitialized = true;
		} else {
			bound.sphereInitialized = false;
		}

		var drawRange = this._drawRanges[id];
		var posAttr = geometry.getAttribute('position');
		drawRange.count = hasIndex ? Std.int(srcIndex.count) : Std.int(posAttr.count);
		this._visibilityChanged = true;

		return id;
	}

	public function deleteGeometry(geometryId:Int):BatchedMesh {
		var active = this._active;
		if (geometryId >= active.length || !active[geometryId]) {
			return this;
		}

		active[geometryId] = false;
		this._visibilityChanged = true;

		return this;
	}

	public function getInstanceCountAt(id:Int):Int {
		if (this._multiDrawInstances == null)
			return null;

		return this._multiDrawInstances[id];
	}

	public function setInstanceCountAt(id:Int, instanceCount:Int):Int {
		if (this._multiDrawInstances == null) {
			this._multiDrawInstances = [];
			for (i in 0...this._maxGeometryCount) {
				this._multiDrawInstances[i] = 1;
			}
		}

		this._multiDrawInstances[id] = instanceCount;

		return id;
	}

	public function getBoundingBoxAt(id:Int, target:Box3):Box3 {
		var active = this._active;
		if (id >= active.length || !active[id]) {
			return null;
		}

		var bound = this._bounds[id];
		var box = bound.box;
		var geometry:BufferGeometry = this.geometry;
		if (!bound.boxInitialized) {
			box.makeEmpty();

			var index = geometry.index;
			var position = geometry.getAttribute('position');
			var drawRange = this._drawRanges[id];
			for (i in drawRange.start...drawRange.start + drawRange.count) {
				var iv = i;
				if (index != null) {
					iv = Std.int(index.getX(iv));
				}

				box.expandByPoint(_vector.fromBufferAttribute(position, iv));
			}

			bound.boxInitialized = true;
		}

		target.copy(box);
		return target;
	}

	public function getBoundingSphereAt(id:Int, target:Sphere):Sphere {
		var active = this._active;
		if (id >= active.length || !active[id]) {
			return null;
		}

		var bound = this._bounds[id];
		var sphere = bound.sphere;
		var geometry:BufferGeometry = this.geometry;
		if (!bound.sphereInitialized) {
			sphere.makeEmpty();

			this.getBoundingBoxAt(id, _box);
			_box.getCenter(sphere.center);

			var index = geometry.index;
			var position = geometry.getAttribute('position');
			var drawRange = this._drawRanges[id];

			var maxRadiusSq:Float = 0;
			for (i in drawRange.start...drawRange.start + drawRange.count) {
				var iv = i;
				if (index != null) {
					iv = Std.int(index.getX(iv));
				}

				_vector.fromBufferAttribute(position, iv);
				maxRadiusSq = Math.max(maxRadiusSq, sphere.center.distanceToSquared(_vector));
			}

			sphere.radius = Math.sqrt(maxRadiusSq);
			bound.sphereInitialized = true;
		}

		target.copy(sphere);
		return target;
	}

	public function setMatrixAt(geometryId:Int, matrix:Matrix4):BatchedMesh {
		var active = this._active;
		var matricesTexture = this._matricesTexture;
		var matricesArray = matricesTexture.image.data;
		var geometryCount:Int = this._geometryCount;
		if (geometryId >= geometryCount || !active[geometryId]) {
			return this;
		}

		matrix.toArray(matricesArray, geometryId * 16);
		matricesTexture.needsUpdate = true;

		return this;
	}

	public function getMatrixAt(geometryId:Int, matrix:Matrix4):Matrix4 {
		var active = this._active;
		var matricesArray = this._matricesTexture.image.data;
		var geometryCount:Int = this._geometryCount;
		if (geometryId >= geometryCount || !active[geometryId]) {
			return null;
		}

		return matrix.fromArray(matricesArray, geometryId * 16);
	}

	public function setColorAt(geometryId:Int, color:Vector3):BatchedMesh {
		if (this._colorsTexture == null) {
			this._initColorsTexture();
		}

		var active = this._active;
		var colorsTexture = this._colorsTexture;
		var colorsArray = colorsTexture.image.data;
		var geometryCount:Int = this._geometryCount;
		if (geometryId >= geometryCount || !active[geometryId]) {
			return this;
		}

		color.toArray(colorsArray, geometryId * 4);
		colorsTexture.needsUpdate = true;

		return this;
	}

	public function getColorAt(geometryId:Int, color:Vector3):Vector3 {
		var active = this._active;
		var colorsArray = this._colorsTexture.image.data;
		var geometryCount:Int = this._geometryCount;
		if (geometryId >= geometryCount || !active[geometryId]) {
			return null;
		}

		return color.fromArray(colorsArray, geometryId * 4);
	}

	public function setVisibleAt(geometryId:Int, value:Bool):BatchedMesh {
		var visibility = this._visibility;
		var active = this._active;
		var geometryCount:Int = this._geometryCount;

		if (geometryId >= geometryCount || !active[geometryId] || visibility[geometryId] == value) {
			return this;
		}

		visibility[geometryId] = value;
		this._visibilityChanged = true;

		return this;
	}

	public function getVisibleAt(geometryId:Int):Bool {
		var visibility = this._visibility;
		var active = this._active;
		var geometryCount:Int = this._geometryCount;

		if (geometryId >= geometryCount || !active[geometryId]) {
			return false;
		}

		return visibility[geometryId];
	}

	override public function raycast(raycaster:Dynamic, intersects:Array<Dynamic>):Void {
		var visibility = this._visibility;
		var active = this._active;
		var drawRanges = this._drawRanges;
		var geometryCount:Int = this._geometryCount;
		var matrixWorld = this.matrixWorld;
		var batchGeometry:BufferGeometry = this.geometry;

		_mesh.material = this.material;
		_mesh.geometry.index = batchGeometry.index;
		_mesh.geometry.attributes = batchGeometry.attributes.clone();
		if (_mesh.geometry.boundingBox == null) {
			_mesh.geometry.boundingBox = new Box3();
		}

		if (_mesh.geometry.boundingSphere == null) {
			_mesh.geometry.boundingSphere = new Sphere();
		}

		for (i in 0...geometryCount) {
			if (!visibility[i] || !active[i]) {
				continue;
			}

			var drawRange = drawRanges[i];
			Reflect.setProperty(_mesh.geometry, "drawRange", {
				start: drawRange.start,
				count: drawRange.count
			});

			this.getMatrixAt(i, _mesh.matrixWorld).premultiply(matrixWorld);
			this.getBoundingBoxAt(i, _mesh.geometry.boundingBox);
			this.getBoundingSphereAt(i, _mesh.geometry.boundingSphere);
			_mesh.raycast(raycaster, _batchIntersects);

			for (j in 0..._batchIntersects.length) {
				var intersect = _batchIntersects[j];
				intersect.object = this;
				intersect.batchId = i;
				intersects.push(intersect);
			}

			_batchIntersects = [];
		}

		_mesh.material = null;
		_mesh.geometry.index = null;
		_mesh.geometry.attributes = new Map();
		Reflect.setProperty(_mesh.geometry, "drawRange", {
			start: 0,
			count: Math.POSITIVE_INFINITY
		});
	}

	override public function copy(source:Dynamic):BatchedMesh {
		super.copy(source);

		this.geometry = cast(source.geometry, BufferGeometry).clone();
		this.perObjectFrustumCulled = source.perObjectFrustumCulled;
		this.sortObjects = source.sortObjects;
		this.boundingBox = source.boundingBox != null ? cast(source.boundingBox, Box3).clone() : null;
		this.boundingSphere = source.boundingSphere != null ? cast(source.boundingSphere, Sphere).clone() : null;

		this._drawRanges = source._drawRanges.map(function(range) {
			return {start: range.start, count: range.count};
		});
		this._reservedRanges = source._reservedRanges.map(function(range) {
			return {
				vertexStart: range.vertexStart,
				vertexCount: range.vertexCount,
				indexStart: range.indexStart,
				indexCount: range.indexCount
			};
		});

		this._visibility = source._visibility.slice();
		this._active = source._active.slice();
		this._bounds = source._bounds.map(function(bound) {
			return {
				boxInitialized: bound.boxInitialized,
				box: bound.box.clone(),

				sphereInitialized: bound.sphereInitialized,
				sphere: bound.sphere.clone()
			};
		});

		this._maxGeometryCount = source._maxGeometryCount;
		this._maxVertexCount = source._maxVertexCount;
		this._maxIndexCount = source._maxIndexCount;

		this._geometryInitialized = source._geometryInitialized;
		this._geometryCount = source._geometryCount;
		this._multiDrawCounts = source._multiDrawCounts.slice();
		this._multiDrawStarts = source._multiDrawStarts.slice();

		this._matricesTexture = cast(source._matricesTexture, DataTexture).clone();
		this._matricesTexture.image.data = this._matricesTexture.image.data.slice();

		if (this._colorsTexture != null) {
			this._colorsTexture = cast(source._colorsTexture, DataTexture).clone();
			this._colorsTexture.image.data = this._colorsTexture.image.data.slice();
		}

		return this;
	}

	override public function dispose():Void {
		this.geometry.dispose();

		this._matricesTexture.dispose();
		this._matricesTexture = null;

		if (this._colorsTexture != null) {
			this._colorsTexture.dispose();
			this._colorsTexture = null;
		}
	}

	@:access(three.Renderer)
	function onBeforeRender(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, material:Dynamic,
			group:Dynamic):Void {
		if (!this._visibilityChanged && !this.perObjectFrustumCulled && !this.sortObjects) {
			return;
		}

		var index = geometry.getIndex();
		var bytesPerElement:Int = index == null ? 1 : 4;

		var active = this._active;
		var visibility = this._visibility;
		var multiDrawStarts = this._multiDrawStarts;
		var multiDrawCounts = this._multiDrawCounts;
		var drawRanges = this._drawRanges;
		var perObjectFrustumCulled:Bool = this.perObjectFrustumCulled;

		if (perObjectFrustumCulled) {
			_projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse).multiply(this.matrixWorld);
			_frustum.setFromProjectionMatrix(_projScreenMatrix, renderer.coordinateSystem);
		}

		var count:Int = 0;
		if (this.sortObjects) {
			_invMatrixWorld.copy(this.matrixWorld).invert();
			_vector.setFromMatrixPosition(camera.matrixWorld).applyMatrix4(_invMatrixWorld);

			for (i in 0...visibility.length) {
				if (visibility[i] && active[i]) {
					this.getMatrixAt(i, _matrix);
					this.getBoundingSphereAt(i, _sphere).applyMatrix4(_matrix);

					var culled:Bool = false;
					if (perObjectFrustumCulled) {
						culled = !_frustum.intersectsSphere(_sphere);
					}

					if (!culled) {
						var z:Float = _vector.distanceTo(_sphere.center);
						_renderList.push(drawRanges[i], z);
					}
				}
			}

			var list = _renderList.data.list;
			var customSort = this.customSort;
			if (customSort == null) {
				list.sort(material.transparent ? function(a, b) -> Int {
					return if (a.z < b.z) 1 else -1;
				} : function(a, b) -> Int {
					return if (a.z > b.z) 1 else -1;
				});
			} else {
				Reflect.callMethod(this, customSort, [list, camera]);
			}

			for (i in 0...list.length) {
				var item = list[i];
				multiDrawStarts[count] = item.start * bytesPerElement;
				multiDrawCounts[count] = item.count;
				count++;
			}

			_renderList.reset();
		} else {
			for (i in 0...visibility.length) {
				if (visibility[i] && active[i]) {
					var culled:Bool = false;
					if (perObjectFrustumCulled) {
						this.getMatrixAt(i, _matrix);
						this.getBoundingSphereAt(i, _sphere).applyMatrix4(_matrix);
						culled = !_frustum.intersectsSphere(_sphere);
					}

					if (!culled) {
						var range = drawRanges[i];
						multiDrawStarts[count] = range.start * bytesPerElement;
						multiDrawCounts[count] = range.count;
						count++;
					}
				}
			}
		}

		this._multiDrawCount = count;
		this._visibilityChanged = false;
	}

	@:access(three.Renderer)
	function onBeforeShadow(renderer:Dynamic, object:Dynamic, camera:Dynamic, shadowCamera:Dynamic, geometry:Dynamic,
			depthMaterial:Dynamic, group:Dynamic):Void {
		this.onBeforeRender(renderer, null, shadowCamera, geometry, depthMaterial, group);
	}
}

private function copyAttributeData(src:BufferAttribute, target:BufferAttribute, targetOffset:Int = 0):Void {
	var itemSize:Int = target.itemSize;
	if (src.array.GetType() != target.array.GetType()) {
		var vertexCount:Int = Std.int(src.count);
		for (i in 0...vertexCount) {
			for (c in 0...itemSize) {
				target.setComponent(i + targetOffset, c, src.getComponent(i, c));
			}
		}
	} else {
		switch (target.array) {
			case Array<Float>(targetArray):
				switch (src.array) {
					case Array<Float>(srcArray):
						for (i in 0...srcArray.length) {
							targetArray[targetOffset * itemSize + i] = srcArray[i];
						}
					default:
				}
			default:
		}
	}

	target.needsUpdate = true;
}