package three.js.src.objects;

import three.js.src.core.BufferAttribute;
import three.js.src.core.BufferGeometry;
import three.js.src.core.Box3;
import three.js.src.core.Sphere;
import three.js.src.materials.Material;
import three.js.src.textures.DataTexture;
import three.js.src.utils.ColorManagement;

class BatchedMesh extends Mesh {
    public var maxGeometryCount(get, never):Int;
    public var isBatchedMesh:Bool;
    public var perObjectFrustumCulled:Bool;
    public var sortObjects:Bool;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;
    public var customSort:Dynamic->Void;

    private var _maxGeometryCount:Int;
    private var _maxVertexCount:Int;
    private var _maxIndexCount:Int;
    private var _drawRanges:Array<DrawRange>;
    private var _reservedRanges:Array<ReservedRange>;
    private var _visibility:Array<Bool>;
    private var _active:Array<Bool>;
    private var _bounds:Array<BoundingBox>;
    private var _geometryInitialized:Bool;
    private var _geometryCount:Int;
    private var _multiDrawCounts:Int32Array;
    private var _multiDrawStarts:Int32Array;
    private var _multiDrawCount:Int;
    private var _multiDrawInstances:Array<Int>;
    private var _visibilityChanged:Bool;
    private var _matricesTexture:DataTexture;
    private var _colorsTexture:DataTexture;

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

        _initMatricesTexture();
    }

    private function _initMatricesTexture() {
        var size:Int = Math.ceil(Math.sqrt(this._maxGeometryCount * 4));
        size = Math.ceil(size / 4) * 4;
        size = Math.max(size, 4);

        var matricesArray:Float32Array = new Float32Array(size * size * 4);
        var matricesTexture:DataTexture = new DataTexture(matricesArray, size, size, RGBAFormat, FloatType);
        this._matricesTexture = matricesTexture;
    }

    private function _initColorsTexture() {
        var size:Int = Math.ceil(Math.sqrt(this._maxGeometryCount));
        size = Math.ceil(size);

        var colorsArray:Float32Array = new Float32Array(size * size * 4);
        var colorsTexture:DataTexture = new DataTexture(colorsArray, size, size, RGBAFormat, FloatType);
        colorsTexture.colorSpace = ColorManagement.workingColorSpace;
        this._colorsTexture = colorsTexture;
    }

    private function _initializeGeometry(reference:BufferGeometry) {
        var geometry:BufferGeometry = this.geometry;
        var maxVertexCount:Int = this._maxVertexCount;
        var maxGeometryCount:Int = this._maxGeometryCount;
        var maxIndexCount:Int = this._maxIndexCount;

        if (!this._geometryInitialized) {
            for (attributeName in reference.attributes) {
                var srcAttribute:BufferAttribute = reference.getAttribute(attributeName);
                var dstArray:Array<Float> = new Array<Float>(maxVertexCount * srcAttribute.itemSize);
                var dstAttribute:BufferAttribute = new BufferAttribute(dstArray, srcAttribute.itemSize, srcAttribute.normalized);

                geometry.setAttribute(attributeName, dstAttribute);
            }

            if (reference.getIndex() != null) {
                var indexArray:Array<Int> = maxVertexCount > 65536 ? new Array<Int>(maxIndexCount) : new Array<Int>(maxIndexCount);
                geometry.setIndex(new BufferAttribute(indexArray, 1));
            }

            var idArray:Array<Int> = maxGeometryCount > 65536 ? new Array<Int>(maxVertexCount) : new Array<Int>(maxVertexCount);
            geometry.setAttribute(ID_ATTR_NAME, new BufferAttribute(idArray, 1));

            this._geometryInitialized = true;
        }
    }

    private function _validateGeometry(geometry:BufferGeometry) {
        // check that the geometry doesn't have a version of our reserved id attribute
        if (geometry.getAttribute(ID_ATTR_NAME) != null) {
            throw new Error("BatchedMesh: Geometry cannot use attribute \"" + ID_ATTR_NAME + "\"");
        }

        // check to ensure the geometries are using consistent attributes and indices
        var batchGeometry:BufferGeometry = this.geometry;
        if (geometry.getIndex() != null != batchGeometry.getIndex()) {
            throw new Error("BatchedMesh: All geometries must consistently have \"index\".");
        }

        for (attributeName in batchGeometry.attributes) {
            if (attributeName == ID_ATTR_NAME) {
                continue;
            }

            if (!geometry.hasAttribute(attributeName)) {
                throw new Error("BatchedMesh: Added geometry missing \"" + attributeName + "\". All geometries must have consistent attributes.");
            }

            var srcAttribute:BufferAttribute = geometry.getAttribute(attributeName);
            var dstAttribute:BufferAttribute = batchGeometry.getAttribute(attributeName);
            if (srcAttribute.itemSize != dstAttribute.itemSize || srcAttribute.normalized != dstAttribute.normalized) {
                throw new Error("BatchedMesh: All attributes must have a consistent itemSize and normalized value.");
            }
        }
    }

    public function setCustomSort(func:Dynamic->Void) {
        this.customSort = func;
        return this;
    }

    public function computeBoundingBox() {
        if (this.boundingBox == null) {
            this.boundingBox = new Box3();
        }

        var geometryCount:Int = this._geometryCount;
        var boundingBox:Box3 = this.boundingBox;
        var active:Array<Bool> = this._active;

        boundingBox.makeEmpty();
        for (i in 0...geometryCount) {
            if (!active[i]) {
                continue;
            }

            this.getMatrixAt(i, _matrix);
            this.getBoundingBoxAt(i, _box).applyMatrix4(_matrix);
            boundingBox.union(_box);
        }
    }

    public function computeBoundingSphere() {
        if (this.boundingSphere == null) {
            this.boundingSphere = new Sphere();
        }

        var geometryCount:Int = this._geometryCount;
        var boundingSphere:Sphere = this.boundingSphere;
        var active:Array<Bool> = this._active;

        boundingSphere.makeEmpty();
        for (i in 0...geometryCount) {
            if (!active[i]) {
                continue;
            }

            this.getMatrixAt(i, _matrix);
            this.getBoundingSphereAt(i, _sphere).applyMatrix4(_matrix);
            boundingSphere.union(_sphere);
        }
    }

    public function addGeometry(geometry:BufferGeometry, vertexCount:Int = -1, indexCount:Int = -1) {
        _initializeGeometry(geometry);

        _validateGeometry(geometry);

        // ensure we're not over geometry
        if (this._geometryCount >= this._maxGeometryCount) {
            throw new Error("BatchedMesh: Maximum geometry count reached.");
        }

        // get the necessary range for the geometry
        var reservedRange:ReservedRange = {
            vertexStart: -1,
            vertexCount: -1,
            indexStart: -1,
            indexCount: -1
        };

        var lastRange:ReservedRange = null;
        var reservedRanges:Array<ReservedRange> = this._reservedRanges;
        var drawRanges:Array<DrawRange> = this._drawRanges;
        var bounds:Array<BoundingBox> = this._bounds;
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

        var index:BufferAttribute = geometry.getIndex();
        var hasIndex:Bool = index != null;
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

        var visibility:Array<Bool> = this._visibility;
        var active:Array<Bool> = this._active;
        var matricesTexture:DataTexture = this._matricesTexture;
        var matricesArray:Float32Array = matricesTexture.image.data;

        // push new visibility states
        visibility.push(true);
        active.push(true);

        // update id
        var geometryId:Int = this._geometryCount;
        this._geometryCount++;

        // initialize matrix information
        _identityMatrix.toArray(matricesArray, geometryId * 16);
        matricesTexture.needsUpdate = true;

        // add the reserved range and draw range objects
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

        // set the id for the geometry
        var idAttribute:BufferAttribute = this.geometry.getAttribute(ID_ATTR_NAME);
        for (i in 0...reservedRange.vertexCount) {
            idAttribute.setX(reservedRange.vertexStart + i, geometryId);
        }

        idAttribute.needsUpdate = true;

        // update the geometry
        setGeometryAt(geometryId, geometry);

        return geometryId;
    }

    public function setGeometryAt(id:Int, geometry:BufferGeometry) {
        if (id >= this._geometryCount) {
            throw new Error("BatchedMesh: Maximum geometry count reached.");
        }

        _validateGeometry(geometry);

        var batchGeometry:BufferGeometry = this.geometry;
        var hasIndex:Bool = batchGeometry.getIndex() != null;
        var dstIndex:BufferAttribute = batchGeometry.getIndex();
        var srcIndex:BufferAttribute = geometry.getIndex();
        var reservedRange:ReservedRange = this._reservedRanges[id];
        if (hasIndex && srcIndex.count > reservedRange.indexCount || geometry.attributes.position.count > reservedRange.vertexCount) {
            throw new Error("BatchedMesh: Reserved space not large enough for provided geometry.");
        }

        // copy geometry over
        var vertexStart:Int = reservedRange.vertexStart;
        var vertexCount:Int = reservedRange.vertexCount;
        for (attributeName in batchGeometry.attributes) {
            if (attributeName == ID_ATTR_NAME) {
                continue;
            }

            // copy attribute data
            var srcAttribute:BufferAttribute = geometry.getAttribute(attributeName);
            var dstAttribute:BufferAttribute = batchGeometry.getAttribute(attributeName);
            copyAttributeData(srcAttribute, dstAttribute, vertexStart);

            // fill the rest in with zeroes
            var itemSize:Int = srcAttribute.itemSize;
            for (i in srcAttribute.count...vertexCount) {
                var index:Int = vertexStart + i;
                for (c in 0...itemSize) {
                    dstAttribute.setComponent(index, c, 0);
                }
            }

            dstAttribute.needsUpdate = true;
            dstAttribute.addUpdateRange(vertexStart * itemSize, vertexCount * itemSize);
        }

        // copy index
        if (hasIndex) {
            var indexStart:Int = reservedRange.indexStart;

            // copy index data over
            for (i in 0...srcIndex.count) {
                dstIndex.setX(indexStart + i, vertexStart + srcIndex.getX(i));
            }

            // fill the rest in with zeroes
            for (i in srcIndex.count...reservedRange.indexCount) {
                dstIndex.setX(indexStart + i, vertexStart);
            }

            dstIndex.needsUpdate = true;
            dstIndex.addUpdateRange(indexStart, reservedRange.indexCount);
        }

        // store the bounding boxes
        var bound:BoundingBox = this._bounds[id];
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
        var drawRange:DrawRange = this._drawRanges[id];
        var posAttr:BufferAttribute = geometry.getAttribute("position");
        drawRange.count = hasIndex ? srcIndex.count : posAttr.count;
        this._visibilityChanged = true;

        return id;
    }

    public function deleteGeometry(geometryId:Int) {
        // Note: User needs to call optimize() afterward to pack the data.

        var active:Array<Bool> = this._active;
        if (geometryId >= active.length || !active[geometryId]) {
            return this;
        }

        active[geometryId] = false;
        this._visibilityChanged = true;

        return this;
    }

    public function getInstanceCountAt(id:Int) {
        if (this._multiDrawInstances == null) return null;

        return this._multiDrawInstances[id];
    }
}