class BatchedMesh extends Mesh {

	public var maxGeometryCount:Int;

	public function new(maxGeometryCount:Int, maxVertexCount:Int, maxIndexCount:Int = maxVertexCount * 2, material:Material) {

		super(new BufferGeometry(), material);

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

		this._matricesTexture = null;
		this._initMatricesTexture();

		this._colorsTexture = null;
		this._initColorsTexture();
	}

	private function _initMatricesTexture() {

		var size = Math.sqrt(this._maxGeometryCount * 4) as Int;
		size = Math.ceil(size / 4) * 4;
		size = Math.max(size, 4);

		var matricesArray = new Float32Array(size * size * 4);
		var matricesTexture = new DataTexture(matricesArray, size, size, RGBAFormat, FloatType);

		this._matricesTexture = matricesTexture;
	}

	private function _initColorsTexture() {

		var size = Math.sqrt(this._maxGeometryCount) as Int;
		size = Math.ceil(size);

		var colorsArray = new Float32Array(size * size * 4);
		var colorsTexture = new DataTexture(colorsArray, size, size, RGBAFormat, FloatType);
		colorsTexture.colorSpace = ColorManagement.workingColorSpace;

		this._colorsTexture = colorsTexture;
	}

	private function _initializeGeometry(reference:Geometry) {

		var geometry = this.geometry;
		var maxVertexCount = this._maxVertexCount;
		var maxGeometryCount = this._maxGeometryCount;
		var maxIndexCount = this._maxIndexCount;
		if (this._geometryInitialized === false) {

			for (attributeName in Reflect.fields(reference.attributes)) {

				var srcAttribute = Reflect.field(reference, attributeName);
				var array = srcAttribute.array;
				var itemSize = srcAttribute.itemSize;
				var normalized = srcAttribute.normalized;

				var dstArray = new array.constructor(maxVertexCount * itemSize);
				var dstAttribute = new BufferAttribute(dstArray, itemSize, normalized);

				Reflect.setField(geometry, attributeName, dstAttribute);
			}

			if (reference.getIndex() !== null) {

				var indexArray = maxVertexCount > 65536
					? new Uint32Array(maxIndexCount)
					: new Uint16Array(maxIndexCount);

				geometry.setIndex(new BufferAttribute(indexArray, 1));
			}

			var idArray = maxGeometryCount > 65536
				? new Uint32Array(maxVertexCount)
				: new Uint16Array(maxVertexCount);
			geometry.setAttribute(ID_ATTR_NAME, new BufferAttribute(idArray, 1));

			this._geometryInitialized = true;
		}
	}

	private function _validateGeometry(geometry:Geometry) {

		if (geometry.getAttribute(ID_ATTR_NAME) !== null) {

			throw "BatchedMesh: Geometry cannot use attribute " + ID_ATTR_NAME;
		}

		if (Boolean(geometry.getIndex()) !== Boolean(this.geometry.getIndex())) {

			throw "BatchedMesh: All geometries must consistently have 'index'.";
		}

		for (attributeName in this.geometry.attributes) {

			if (attributeName == ID_ATTR_NAME) {

				continue;
			}

			if (!geometry.hasAttribute(attributeName)) {

				throw "BatchedMesh: Added geometry missing '" + attributeName + "'. All geometries must have consistent attributes.";
			}

			var srcAttribute = geometry.getAttribute(attributeName);
			var dstAttribute = this.geometry.getAttribute(attributeName);
			if (srcAttribute.itemSize !== dstAttribute.itemSize || srcAttribute.normalized !== dstAttribute.normalized) {

				throw "BatchedMesh: All attributes must have a consistent itemSize and normalized value.";
			}
		}
	}

	public function setCustomSort(func:Dynamic) {

		this.customSort = func;
		return this;
	}

	public function computeBoundingBox() {

		if (this.boundingBox === null) {

			this.boundingBox = new Box3();
		}

		var geometryCount = this._geometryCount;
		var boundingBox = this.boundingBox;
		var active = this._active;

		boundingBox.makeEmpty();
		for (i in 0...geometryCount) {

			if (active[i] === false) continue;

			this.getMatrixAt(i, _matrix);
			this.getBoundingBoxAt(i, _box).applyMatrix4(_matrix);
			boundingBox.union(_box);
		}
	}

	public function computeBoundingSphere() {

		if (this.boundingSphere === null) {

			this.boundingSphere = new Sphere();
		}

		var geometryCount = this._geometryCount;
		var boundingSphere = this.boundingSphere;
		var active = this._active;

		boundingSphere.makeEmpty();
		for (i in 0...geometryCount) {

			if (active[i] === false) continue;

			this.getMatrixAt(i, _matrix);
			this.getBoundingSphereAt(i, _sphere).applyMatrix4(_matrix);
			boundingSphere.union(_sphere);
		}
	}

	public function addGeometry(geometry:Geometry, vertexCount:Int = -1, indexCount:Int = -1) {

		this._initializeGeometry(geometry);

		this._validateGeometry(geometry);

		if (this._geometryCount >= this._maxGeometryCount) {

			throw "BatchedMesh: Maximum geometry count reached.";
		}

		var reservedRange = {
			vertexStart: -1,
			vertexCount: -1,
			indexStart: -1,
			indexCount: -1
		};

		var lastRange = null;
		var reservedRanges = this._reservedRanges;
		var drawRanges = this._drawRanges;
		var bounds = this._bounds;
		if (this._geometryCount !== 0) {

			lastRange = reservedRanges[reservedRanges.length - 1];
		}

		if (vertexCount === -1) {

			reservedRange.vertexCount = geometry.getAttribute('position').count;
		} else {

			reservedRange.vertexCount = vertexCount;
		}

		if (lastRange === null) {

			reservedRange.vertexStart = 0;
		} else {

			reservedRange.vertexStart = lastRange.vertexStart + lastRange.vertexCount;
		}

		var index = geometry.getIndex();
		var hasIndex = index !== null;
		if (hasIndex) {

			if (indexCount === -1) {

				reservedRange.indexCount = index.count;
			} else {

				reservedRange.indexCount = indexCount;
			}

			if (lastRange === null) {

				reservedRange.indexStart = 0;
			} else {

				reservedRange.indexStart = lastRange.indexStart + lastRange.indexCount;
			}
		}

		if (
			reservedRange.indexStart !== -1 &&
			reservedRange.indexStart + reservedRange.indexCount > this._maxIndexCount ||
			reservedRange.vertexStart + reservedRange.vertexCount > this._maxVertexCount
		) {

			throw "BatchedMesh: Reserved space request exceeds the maximum buffer size.";
		}

		var visibility = this._visibility;
		var active = this._active;
		var matricesTexture = this._matricesTexture;
		var matricesArray = this._matricesTexture.image.data;

		visibility.push(true);
		active.push(true);

		this._geometryCount++;

		_identityMatrix.toArray(matricesArray, this._geometryCount * 16);
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

		var geometryId = this._geometryCount - 1;
		var idAttribute = this.geometry.getAttribute(ID_ATTR_NAME);
		for (i in 0...reservedRange.vertexCount) {

			idAttribute.setX(reservedRange.vertexStart + i, geometryId);
		}

		idAttribute.needsUpdate = true;

		this.setGeometryAt(geometryId, geometry);

		return geometryId;
	}

	public function setGeometryAt(id:Int, geometry:Geometry) {

		if (id >= this._geometryCount) {

			throw "BatchedMesh: Maximum geometry count reached.";
		}

		this._validateGeometry(geometry);

		var batchGeometry = this.geometry;
		var hasIndex = batchGeometry.getIndex() !== null;
		var dstIndex = batchGeometry.getIndex();
		var srcIndex = geometry.getIndex();
		var reservedRange = this._reservedRanges[id];
		if (
			hasIndex &&
			srcIndex.count > reservedRange.indexCount ||
			geometry.attributes.position.count > reservedRange.vertexCount
		) {

			throw "BatchedMesh: Reserved space not large enough for provided geometry.";
		}

		var vertexStart = reservedRange.vertexStart;
		var vertexCount = reservedRange.vertexCount;
		for (attributeName in batchGeometry.attributes) {

			if (attributeName == ID_ATTR_NAME) {

				continue;
			}

			var srcAttribute = geometry.getAttribute(attributeName);
			var dstAttribute = batchGeometry.getAttribute(attributeName);
			copyAttributeData(srcAttribute, dstAttribute, vertexStart);

			var itemSize = srcAttribute.itemSize;
			for (i in srcAttribute.count...vertexCount) {

				var index = vertexStart + i;
				for (c in 0...itemSize) {

					dstAttribute.setComponent(index, c, 0);
				}
			}

			dstAttribute.needsUpdate = true;
			dstAttribute.addUpdateRange(vertexStart * itemSize, vertexCount * itemSize);
		}

		if (hasIndex) {

			var indexStart = reservedRange.indexStart;

			for (i in 0...srcIndex.count) {

				dstIndex.setX(indexStart + i, vertexStart + srcIndex.getX(i));
			}

			for (i in srcIndex.count...reservedRange.indexCount) {

				dstIndex.setX(indexStart + i, vertexStart);
			}

			dstIndex.needsUpdate = true;
			dstIndex.addUpdateRange(indexStart, reservedRange.indexCount);
		}

		var bound = this._bounds[id];
		if (geometry.boundingBox !== null) {

			bound.box.copy(geometry.boundingBox);
			bound.boxInitialized = true;
		} else {

			bound.boxInitialized = false;
		}

		if (geometry.boundingSphere !== null) {

			bound.sphere.copy(geometry.boundingSphere);
			bound.sphereInitialized = true;
		} else {

			bound.sphereInitialized = false;
		}

		var drawRange = this._drawRanges[id];
		var posAttr = geometry.getAttribute('position');
		drawRange.count = hasIndex ? srcIndex.count : posAttr.count;
		this._visibilityChanged = true;

		return id;
	}

	public function deleteGeometry(geometryId:Int) {

		var active = this._active;
		if (geometryId >= active.length || active[geometryId] === false) {

			return this;
		}

		active[geometryId] = false;
		this._visibilityChanged = true;

		return this;
	}

	public function getInstanceCountAt(id:Int) {

		if (this._multiDrawInstances === null) return null;

		return this._multiDrawInstances[id];
	}
}