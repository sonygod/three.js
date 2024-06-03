import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.display.IBitmapDrawable;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;
import openfl.utils.Int32Array;
import openfl.utils.UInt32Array;
import openfl.utils.Vector;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.core.Object3D;
import three.math.Box3;
import three.math.Frustum;
import three.math.Matrix4;
import three.math.Sphere;
import three.math.Vector3;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.textures.DataTexture;
import three.textures.Texture;
import three.textures.TextureBase;

class MultiDrawRenderList {
	public var index:Int = 0;
	public var pool:Array<{ start:Int, count:Int, z:Float }> = [];
	public var list:Array<{ start:Int, count:Int, z:Float }> = [];

	public function new() {
	}

	public function push(drawRange: { start:Int, count:Int }, z:Float):Void {
		var pool = this.pool;
		var list = this.list;
		if (this.index >= pool.length) {
			pool.push({
				start: - 1,
				count: - 1,
				z: - 1,
			});
		}

		var item = pool[this.index];
		list.push(item);
		this.index++;

		item.start = drawRange.start;
		item.count = drawRange.count;
		item.z = z;
	}

	public function reset():Void {
		this.list.length = 0;
		this.index = 0;
	}
}

const ID_ATTR_NAME:String = "batchId";
var _matrix:Matrix4 = new Matrix4();
var _invMatrixWorld:Matrix4 = new Matrix4();
var _identityMatrix:Matrix4 = new Matrix4();
var _projScreenMatrix:Matrix4 = new Matrix4();
var _frustum:Frustum = new Frustum();
var _box:Box3 = new Box3();
var _sphere:Sphere = new Sphere();
var _vector:Vector3 = new Vector3();
var _renderList:MultiDrawRenderList = new MultiDrawRenderList();
var _mesh:Object3D = new Object3D();
var _batchIntersects:Array<Dynamic> = [];

// @TODO: SkinnedMesh support?
// @TODO: geometry.groups support?
// @TODO: geometry.drawRange support?
// @TODO: geometry.morphAttributes support?
// @TODO: Support uniform parameter per geometry
// @TODO: Add an "optimize" function to pack geometry and remove data gaps

// copies data from attribute "src" into "target" starting at "targetOffset"
function copyAttributeData(src:BufferAttribute, target:BufferAttribute, targetOffset:Int = 0):Void {
	var itemSize = target.itemSize;
	if (src.isInterleavedBufferAttribute || src.array.constructor != target.array.constructor) {
		// use the component getters and setters if the array data cannot
		// be copied directly
		var vertexCount = src.count;
		for (var i in 0...vertexCount) {
			for (var c in 0...itemSize) {
				target.setComponent(i + targetOffset, c, src.getComponent(i, c));
			}
		}
	} else {
		// faster copy approach using typed array set function
		target.array.set(src.array, targetOffset * itemSize);
	}

	target.needsUpdate = true;
}

class BatchedMesh extends Object3D {
	public var maxGeometryCount(get, never):Int;
	private var _maxGeometryCount:Int;

	public function new(maxGeometryCount:Int, maxVertexCount:Int, maxIndexCount:Int = maxVertexCount * 2, material:Dynamic) {
		super();
		this.geometry = new BufferGeometry();
		this.material = material;

		this.isBatchedMesh = true;
		this.perObjectFrustumCulled = true;
		this.sortObjects = true;
		this.boundingBox = null;
		this.boundingSphere = null;
		this.customSort = null;

		this._drawRanges = [];
		this._reservedRanges = [];

		this._visibility = [];
		this._active = [];
		this._bounds = [];

		this._maxGeometryCount = maxGeometryCount;
		this._maxVertexCount = maxVertexCount;
		this._maxIndexCount = maxIndexCount;

		this._geometryInitialized = false;
		this._geometryCount = 0;
		this._multiDrawCounts = new Int32Array(maxGeometryCount);
		this._multiDrawStarts = new Int32Array(maxGeometryCount);
		this._multiDrawCount = 0;
		this._multiDrawInstances = null;
		this._visibilityChanged = true;

		// Local matrix per geometry by using data texture
		this._matricesTexture = null;

		this._initMatricesTexture();

		// Local color per geometry by using data texture
		this._colorsTexture = null;
	}

	private function _initMatricesTexture():Void {
		// layout (1 matrix = 4 pixels)
		//      RGBA RGBA RGBA RGBA (=> column1, column2, column3, column4)
		//  with  8x8  pixel texture max   16 matrices * 4 pixels =  (8 * 8)
		//       16x16 pixel texture max   64 matrices * 4 pixels = (16 * 16)
		//       32x32 pixel texture max  256 matrices * 4 pixels = (32 * 32)
		//       64x64 pixel texture max 1024 matrices * 4 pixels = (64 * 64)

		var size = Math.sqrt(this._maxGeometryCount * 4); // 4 pixels needed for 1 matrix
		size = Math.ceil(size / 4) * 4;
		size = Math.max(size, 4);

		var matricesArray = new Float32Array(size * size * 4); // 4 floats per RGBA pixel
		var matricesTexture = new DataTexture(matricesArray, size, size, TextureBase.RGBAFormat, TextureBase.FloatType);

		this._matricesTexture = matricesTexture;
	}

	private function _initColorsTexture():Void {
		var size = Math.sqrt(this._maxGeometryCount);
		size = Math.ceil(size);

		var colorsArray = new Float32Array(size * size * 4); // 4 floats per RGBA pixel
		var colorsTexture = new DataTexture(colorsArray, size, size, TextureBase.RGBAFormat, TextureBase.FloatType);
		colorsTexture.colorSpace = 0; // ColorManagement.workingColorSpace;

		this._colorsTexture = colorsTexture;
	}

	private function _initializeGeometry(reference:BufferGeometry):Void {
		var geometry = this.geometry;
		var maxVertexCount = this._maxVertexCount;
		var maxGeometryCount = this._maxGeometryCount;
		var maxIndexCount = this._maxIndexCount;
		if (this._geometryInitialized == false) {
			for (var attributeName in reference.attributes) {
				var srcAttribute = reference.getAttribute(attributeName);
				var { array, itemSize, normalized } = srcAttribute;

				var dstArray = new srcAttribute.array.constructor(maxVertexCount * itemSize);
				var dstAttribute = new BufferAttribute(dstArray, itemSize, normalized);

				geometry.setAttribute(attributeName, dstAttribute);
			}

			if (reference.index != null) {
				var indexArray = maxVertexCount > 65536 ? new UInt32Array(maxIndexCount) : new UInt16Array(maxIndexCount);

				geometry.setIndex(new BufferAttribute(indexArray, 1));
			}

			var idArray = maxGeometryCount > 65536 ? new UInt32Array(maxVertexCount) : new UInt16Array(maxVertexCount);
			geometry.setAttribute(ID_ATTR_NAME, new BufferAttribute(idArray, 1));

			this._geometryInitialized = true;
		}
	}

	// Make sure the geometry is compatible with the existing combined geometry attributes
	private function _validateGeometry(geometry:BufferGeometry):Void {
		// check that the geometry doesn't have a version of our reserved id attribute
		if (geometry.getAttribute(ID_ATTR_NAME)) {
			throw new Error("BatchedMesh: Geometry cannot use attribute \"${ID_ATTR_NAME}\"");
		}

		// check to ensure the geometries are using consistent attributes and indices
		var batchGeometry = this.geometry;
		if (geometry.index != null != batchGeometry.index != null) {
			throw new Error("BatchedMesh: All geometries must consistently have \"index\".");
		}

		for (var attributeName in batchGeometry.attributes) {
			if (attributeName == ID_ATTR_NAME) {
				continue;
			}

			if (!geometry.hasAttribute(attributeName)) {
				throw new Error("BatchedMesh: Added geometry missing \"${attributeName}\". All geometries must have consistent attributes.");
			}

			var srcAttribute = geometry.getAttribute(attributeName);
			var dstAttribute = batchGeometry.getAttribute(attributeName);
			if (srcAttribute.itemSize != dstAttribute.itemSize || srcAttribute.normalized != dstAttribute.normalized) {
				throw new Error("BatchedMesh: All attributes must have a consistent itemSize and normalized value.");
			}
		}
	}

	public function setCustomSort(func:Dynamic):BatchedMesh {
		this.customSort = func;
		return this;
	}

	public function computeBoundingBox():Void {
		if (this.boundingBox == null) {
			this.boundingBox = new Box3();
		}

		var geometryCount = this._geometryCount;
		var boundingBox = this.boundingBox;
		var active = this._active;

		boundingBox.makeEmpty();
		for (var i in 0...geometryCount) {
			if (active[i] == false) continue;

			this.getMatrixAt(i, _matrix);
			this.getBoundingBoxAt(i, _box).applyMatrix4(_matrix);
			boundingBox.union(_box);
		}
	}

	public function computeBoundingSphere():Void {
		if (this.boundingSphere == null) {
			this.boundingSphere = new Sphere();
		}

		var geometryCount = this._geometryCount;
		var boundingSphere = this.boundingSphere;
		var active = this._active;

		boundingSphere.makeEmpty();
		for (var i in 0...geometryCount) {
			if (active[i] == false) continue;

			this.getMatrixAt(i, _matrix);
			this.getBoundingSphereAt(i, _sphere).applyMatrix4(_matrix);
			boundingSphere.union(_sphere);
		}
	}

	public function addGeometry(geometry:BufferGeometry, vertexCount:Int = -1, indexCount:Int = -1):Int {
		this._initializeGeometry(geometry);

		this._validateGeometry(geometry);

		// ensure we're not over geometry
		if (this._geometryCount >= this._maxGeometryCount) {
			throw new Error("BatchedMesh: Maximum geometry count reached.");
		}

		// get the necessary range fo the geometry
		var reservedRange = {
			vertexStart: - 1,
			vertexCount: - 1,
			indexStart: - 1,
			indexCount: - 1,
		};

		var lastRange:Dynamic = null;
		var reservedRanges = this._reservedRanges;
		var drawRanges = this._drawRanges;
		var bounds = this._bounds;
		if (this._geometryCount != 0) {
			lastRange = reservedRanges[reservedRanges.length - 1];
		}

		if (vertexCount == -1) {
			reservedRange.vertexCount = geometry.getAttribute("position").count;
		} else {
			reservedRange.vertexCount = vertexCount;
		}

		if (lastRange == null) {
			reservedRange.vertexStart = 0;
		} else {
			reservedRange.vertexStart = lastRange.vertexStart + lastRange.vertexCount;
		}

		var index = geometry.getIndex();
		var hasIndex = index != null;
		if (hasIndex) {
			if (indexCount == -1) {
				reservedRange.indexCount = index.count;
			} else {
				reservedRange.indexCount = indexCount;
			}

			if (lastRange == null) {
				reservedRange.indexStart = 0;
			} else {
				reservedRange.indexStart = lastRange.indexStart + lastRange.indexCount;
			}
		}

		if (reservedRange.indexStart != -1 && reservedRange.indexStart + reservedRange.indexCount > this._maxIndexCount || reservedRange.vertexStart + reservedRange.vertexCount > this._maxVertexCount) {
			throw new Error("BatchedMesh: Reserved space request exceeds the maximum buffer size.");
		}

		var visibility = this._visibility;
		var active = this._active;
		var matricesTexture = this._matricesTexture;
		var matricesArray = this._matricesTexture.image.data;

		// push new visibility states
		visibility.push(true);
		active.push(true);

		// update id
		var geometryId = this._geometryCount;
		this._geometryCount++;

		// initialize matrix information
		_identityMatrix.toArray(matricesArray, geometryId * 16);
		matricesTexture.needsUpdate = true;

		// add the reserved range and draw range objects
		reservedRanges.push(reservedRange);
		drawRanges.push({
			start: hasIndex ? reservedRange.indexStart : reservedRange.vertexStart,
			count: - 1
		});
		bounds.push({
			boxInitialized: false,
			box: new Box3(),

			sphereInitialized: false,
			sphere: new Sphere()
		});

		// set the id for the geometry
		var idAttribute = this.geometry.getAttribute(ID_ATTR_NAME);
		for (var i in 0...reservedRange.vertexCount) {
			idAttribute.setX(reservedRange.vertexStart + i, geometryId);
		}

		idAttribute.needsUpdate = true;

		// update the geometry
		this.setGeometryAt(geometryId, geometry);

		return geometryId;
	}

	public function setGeometryAt(id:Int, geometry:BufferGeometry):Int {
		if (id >= this._geometryCount) {
			throw new Error("BatchedMesh: Maximum geometry count reached.");
		}

		this._validateGeometry(geometry);

		var batchGeometry = this.geometry;
		var hasIndex = batchGeometry.getIndex() != null;
		var dstIndex = batchGeometry.getIndex();
		var srcIndex = geometry.getIndex();
		var reservedRange = this._reservedRanges[id];
		if (hasIndex && srcIndex.count > reservedRange.indexCount || geometry.attributes.position.count > reservedRange.vertexCount) {
			throw new Error("BatchedMesh: Reserved space not large enough for provided geometry.");
		}

		// copy geometry over
		var vertexStart = reservedRange.vertexStart;
		var vertexCount = reservedRange.vertexCount;
		for (var attributeName in batchGeometry.attributes) {
			if (attributeName == ID_ATTR_NAME) {
				continue;
			}

			// copy attribute data
			var srcAttribute = geometry.getAttribute(attributeName);
			var dstAttribute = batchGeometry.getAttribute(attributeName);
			copyAttributeData(srcAttribute, dstAttribute, vertexStart);

			// fill the rest in with zeroes
			var itemSize = srcAttribute.itemSize;
			for (var i = srcAttribute.count, l = vertexCount; i < l; i++) {
				var index = vertexStart + i;
				for (var c in 0...itemSize) {
					dstAttribute.setComponent(index, c, 0);
				}
			}

			dstAttribute.needsUpdate = true;
			dstAttribute.addUpdateRange(vertexStart * itemSize, vertexCount * itemSize);
		}

		// copy index
		if (hasIndex) {
			var indexStart = reservedRange.indexStart;

			// copy index data over
			for (var i in 0...srcIndex.count) {
				dstIndex.setX(indexStart + i, vertexStart + srcIndex.getX(i));
			}

			// fill the rest in with zeroes
			for (var i = srcIndex.count, l = reservedRange.indexCount; i < l; i++) {
				dstIndex.setX(indexStart + i, vertexStart);
			}

			dstIndex.needsUpdate = true;
			dstIndex.addUpdateRange(indexStart, reservedRange.indexCount);
		}

		// store the bounding boxes
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

		// set drawRange count
		var drawRange = this._drawRanges[id];
		var posAttr = geometry.getAttribute("position");
		drawRange.count = hasIndex ? srcIndex.count : posAttr.count;
		this._visibilityChanged = true;

		return id;
	}

	public function deleteGeometry(geometryId:Int):BatchedMesh {
		// Note: User needs to call optimize() afterward to pack the data.

		var active = this._active;
		if (geometryId >= active.length || active[geometryId] == false) {
			return this;
		}

		active[geometryId] = false;
		this._visibilityChanged = true;

		return this;
	}

	public function getInstanceCountAt(id:Int):Int {
		if (this._multiDrawInstances == null) return null;

		return this._multiDrawInstances[id];
	}

	public function setInstanceCountAt(id:Int, instanceCount:Int):Int {
		if (this._multiDrawInstances == null) {
			this._multiDrawInstances = new Int32Array(this._maxGeometryCount).fill(1);
		}

		this._multiDrawInstances[id] = instanceCount;

		return id;
	}

	// get bounding box and compute it if it doesn't exist
	public function getBoundingBoxAt(id:Int, target:Box3):Box3 {
		var active = this._active;
		if (active[id] == false) {
			return null;
		}

		// compute bounding box
		var bound = this._bounds[id];
		var box = bound.box;
		var geometry = this.geometry;
		if (bound.boxInitialized == false) {
			box.makeEmpty();

			var index = geometry.index;
			var position = geometry.attributes.position;
			var drawRange = this._drawRanges[id];
			for (var i = drawRange.start, l = drawRange.start + drawRange.count; i < l; i++) {
				var iv = i;
				if (index) {
					iv = index.getX(iv);
				}

				box.expandByPoint(_vector.fromBufferAttribute(position, iv));
			}

			bound.boxInitialized = true;
		}

		target.copy(box);
		return target;
	}

	// get bounding sphere and compute it if it doesn't exist
	public function getBoundingSphereAt(id:Int, target:Sphere):Sphere {
		var active = this._active;
		if (active[id] == false) {
			return null;
		}

		// compute bounding sphere
		var bound = this._bounds[id];
		var sphere = bound.sphere;
		var geometry = this.geometry;
		if (bound.sphereInitialized == false) {
			sphere.makeEmpty();

			this.getBoundingBoxAt(id, _box);
			_box.getCenter(sphere.center);

			var index = geometry.index;
			var position = geometry.attributes.position;
			var drawRange = this._drawRanges[id];

			var maxRadiusSq = 0;
			for (var i = drawRange.start, l = drawRange.start + drawRange.count; i < l; i++) {
				var iv = i;
				if (index) {
					iv = index.getX(iv);
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
		// @TODO: Map geometryId to index of the arrays because
		//        optimize() can make geometryId mismatch the index

		var active = this._active;
		var matricesTexture = this._matricesTexture;
		var matricesArray = this._matricesTexture.image.data;
		var geometryCount = this._geometryCount;
		if (geometryId >= geometryCount || active[geometryId] == false) {
			return this;
		}

		matrix.toArray(matricesArray, geometryId * 16);
		matricesTexture.needsUpdate = true;

		return this;
	}

	public function getMatrixAt(geometryId:Int, matrix:Matrix4):Matrix4 {
		var active = this._active;
		var matricesArray = this._matricesTexture.image.data;
		var geometryCount = this._geometryCount;
		if (geometryId >= geometryCount || active[geometryId] == false) {
			return null;
		}

		return matrix.fromArray(matricesArray, geometryId * 16);
	}

	public function setColorAt(geometryId:Int, color:Dynamic):BatchedMesh {
		if (this._colorsTexture == null) {
			this._initColorsTexture();
		}

		// @TODO: Map geometryId to index of the arrays because
		//        optimize() can make geometryId mismatch the index

		var active = this._active;
		var colorsTexture = this._colorsTexture;
		var colorsArray = this._colorsTexture.image.data;
		var geometryCount = this._geometryCount;
		if (geometryId >= geometryCount || active[geometryId] == false) {
			return this;
		}

		color.toArray(colorsArray, geometryId * 4);
		colorsTexture.needsUpdate = true;

		return this;
	}

	public function getColorAt(geometryId:Int, color:Dynamic):Dynamic {
		var active = this._active;
		var colorsArray = this._colorsTexture.image.data;
		var geometryCount = this._geometryCount;
		if (geometryId >= geometryCount || active[geometryId] == false) {
			return null;
		}

		return color.fromArray(colorsArray, geometryId * 4);
	}

	public function setVisibleAt(geometryId:Int, value:Bool):BatchedMesh {
		var visibility = this._visibility;
		var active = this._active;
		var geometryCount = this._geometryCount;

		// if the geometry is out of range, not active, or visibility state
		// does not change then return early
		if (geometryId >= geometryCount || active[geometryId] == false || visibility[geometryId] == value) {
			return this;
		}

		visibility[geometryId] = value;
		this._visibilityChanged = true;

		return this;
	}

	public function getVisibleAt(geometryId:Int):Bool {
		var visibility = this._visibility;
		var active = this._active;
		var geometryCount = this._geometryCount;

		// return early if the geometry is out of range or not active
		if (geometryId >= geometryCount || active[geometryId] == false) {
			return false;
		}

		return visibility[geometryId];
	}

	public function raycast(raycaster:Dynamic, intersects:Array<Dynamic>):Void {
		var visibility = this._visibility;
		var active = this._active;
		var drawRanges = this._drawRanges;
		var geometryCount = this._geometryCount;
		var matrixWorld = this.matrixWorld;
		var batchGeometry = this.geometry;

		// iterate over each geometry
		_mesh.material = this.material;
		_mesh.geometry.index = batchGeometry.index;
		_mesh.geometry.attributes = batchGeometry.attributes;
		if (_mesh.geometry.boundingBox == null) {
			_mesh.geometry.boundingBox = new Box3();
		}

		if (_mesh.geometry.boundingSphere == null) {
			_mesh.geometry.boundingSphere = new Sphere();
		}

		for (var i in 0...geometryCount) {
			if (!visibility[i] || !active[i]) {
				continue;
			}

			var drawRange = drawRanges[i];
			_mesh.geometry.setDrawRange(drawRange.start, drawRange.count);

			// ge the intersects
			this.getMatrixAt(i, _mesh.matrixWorld).premultiply(matrixWorld);
			this.getBoundingBoxAt(i, _mesh.geometry.boundingBox);
			this.getBoundingSphereAt(i, _mesh.geometry.boundingSphere);
			_mesh.raycast(raycaster, _batchIntersects);

			// add batch id to the intersects
			for (var j in 0..._batchIntersects.length) {
				var intersect = _batchIntersects[j];
				intersect.object = this;
				intersect.batchId = i;
				intersects.push(intersect);
			}

			_batchIntersects.length = 0;
		}

		_mesh.material = null;
		_mesh.geometry.index = null;
		_mesh.geometry.attributes = {};
		_mesh.geometry.setDrawRange(0, 16777216);
	}

	public function copy(source:BatchedMesh):BatchedMesh {
		super.copy(source);

		this.geometry = source.geometry.clone();
		this.perObjectFrustumCulled = source.perObjectFrustumCulled;
		this.sortObjects = source.sortObjects;
		this.boundingBox = source.boundingBox != null ? source.boundingBox.clone() : null;
		this.boundingSphere = source.boundingSphere != null ? source.boundingSphere.clone() : null;

		this._drawRanges = source._drawRanges.map(range => ({ ...range }));
		this._reservedRanges = source._reservedRanges.map(range => ({ ...range }));

		this._visibility = source._visibility.copy();
		this._active = source._active.copy();
		this._bounds = source._bounds.map(bound => ({
			boxInitialized: bound.boxInitialized,
			box: bound.box.clone(),

			sphereInitialized: bound.sphereInitialized,
			sphere: bound.sphere.clone()
		}));

		this._maxGeometryCount = source._maxGeometryCount;
		this._maxVertexCount = source._maxVertexCount;
		this._maxIndexCount = source._maxIndexCount;

		this._geometryInitialized = source._geometryInitialized;
		this._geometryCount = source._geometryCount;
		this._multiDrawCounts = source._multiDrawCounts.copy();
		this._multiDrawStarts = source._multiDrawStarts.copy();

		this._matricesTexture = source._matricesTexture.clone();
		this._matricesTexture.image.data = this._matricesTexture.image.slice();

		if (this._colorsTexture != null) {
			this._colorsTexture = source._colorsTexture.clone();
			this._colorsTexture.image.data = this._colorsTexture.image.slice();
		}

		return this;
	}

	public function dispose():BatchedMesh {
		// Assuming the geometry is not shared with other meshes
		this.geometry.dispose();

		this._matricesTexture.dispose();
		this._matricesTexture = null;

		if (this._colorsTexture != null) {
			this._colorsTexture.dispose();
			this._colorsTexture = null;
		}

		return this;
	}

	public function onBeforeRender(renderer:WebGLRenderer, scene:Scene, camera:Dynamic, geometry:BufferGeometry, material:Dynamic, _group:Dynamic):Void {
		// if visibility has not changed and frustum culling and object sorting is not required
		// then skip iterating over all items
		if (!this._visibilityChanged && !this.perObjectFrustumCulled && !this.sortObjects) {
			return;
		}

		// the indexed version of the multi draw function requires specifying the start
		// offset in bytes.
		var index = geometry.getIndex();
		var bytesPerElement = index == null ? 1 : index.array.BYTES_PER_ELEMENT;

		var active = this._active;
		var visibility = this._visibility;
		var multiDrawStarts = this._multiDrawStarts;
		var multiDrawCounts = this._multiDrawCounts;
		var drawRanges = this._drawRanges;
		var perObjectFrustumCulled = this.perObjectFrustumCulled;

		// prepare the frustum in the local frame
		if (perObjectFrustumCulled) {
			_projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse).multiply(this.matrixWorld);
			_frustum.setFromProjectionMatrix(_projScreenMatrix, renderer.coordinateSystem);
		}

		var count = 0;
		if (this.sortObjects) {
			// get the camera position in the local frame
			_invMatrixWorld.copy(this.matrixWorld).invert();
			_vector.setFromMatrixPosition(camera.matrixWorld).applyMatrix4(_invMatrixWorld);

			for (var i in 0...visibility.length) {
				if (visibility[i] && active[i]) {
					// get the bounds in world space
					this.getMatrixAt(i, _matrix);
					this.getBoundingSphereAt(i, _sphere).applyMatrix4(_matrix);

					// determine whether the batched geometry is within the frustum
					var culled = false;
					if (perObjectFrustumCulled) {
						culled = !_frustum.intersectsSphere(_sphere);
					}

					if (!culled) {
						// get the distance from camera used for sorting
						var z = _vector.distanceTo(_sphere.center);
						_renderList.push(drawRanges[i], z);
					}
				}
			}

			// Sort the draw ranges and prep for rendering
			var list = _renderList.list;
			var customSort = this.customSort;
			if (customSort == null) {
				list.sort(material.transparent ? sortTransparent : sortOpaque);
			} else {
				customSort.call(this, list, camera);
			}

			for (var i in 0...list.length) {
				var item = list[i];
				multiDrawStarts[count] = item.start * bytesPerElement;
				multiDrawCounts[count] = item.count;
				count++;
			}

			_renderList.reset();
		} else {
			for (var i in 0...visibility.length) {
				if (visibility[i] && active[i]) {
					// determine whether the batched geometry is within the frustum
					var culled = false;
					if (perObjectFrustumCulled) {
						// get the bounds in world space
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

	public function onBeforeShadow(renderer:WebGLRenderer, object:Object3D, camera:Dynamic, shadowCamera:Dynamic, geometry:BufferGeometry, depthMaterial:Dynamic, _group:Dynamic):Void {
		this.onBeforeRender(renderer, null, shadowCamera, geometry, depthMaterial);
	}

	private var _drawRanges:Array<{ start:Int, count:Int }> = [];
	private var _reservedRanges:Array<{ vertexStart:Int, vertexCount:Int, indexStart:Int, indexCount:Int }> = [];
	private var _visibility:Array<Bool> = [];
	private var _active:Array<Bool> = [];
	private var _bounds:Array<{ boxInitialized:Bool, box:Box3, sphereInitialized:Bool, sphere:Sphere }> = [];
	private var _geometryInitialized:Bool = false;
	private var _geometryCount:Int = 0;
	private var _multiDrawCounts:Int32Array;
	private var _multiDrawStarts:Int32Array;
	private var _multiDrawCount:Int = 0;
	private var _multiDrawInstances:Int32Array;
	private var _visibilityChanged:Bool = true;
	private var _matricesTexture:DataTexture;
	private var _colorsTexture:DataTexture;

	private var isBatchedMesh:Bool = false;
	private var perObjectFrustumCulled:Bool = false;
	private var sortObjects:Bool = false;
	private var boundingBox:Box3;
	private var boundingSphere:Sphere;
	private var customSort:Dynamic;

	public var maxGeometryCount(get, never):Int {
		return this._maxGeometryCount;
	}
}

function sortOpaque(a: { z:Float }, b: { z:Float }):Int {
	return a.z - b.z;
}

function sortTransparent(a: { z:Float }, b: { z:Float }):Int {
	return b.z - a.z;
}