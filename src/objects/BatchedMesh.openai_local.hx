import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.textures.DataTexture;
import three.constants.FloatType;
import three.math.Matrix4;
import three.objects.Mesh;
import three.constants.RGBAFormat;
import three.math.ColorManagement;
import three.math.Box3;
import three.math.Sphere;
import three.math.Frustum;
import three.math.Vector3;

class MultiDrawRenderList {

    public var index:Int;
    public var pool:Array<Dynamic>;
    public var list:Array<Dynamic>;

    public function new() {
        this.index = 0;
        this.pool = [];
        this.list = [];
    }

    public function push(drawRange:Dynamic, z:Float):Void {
        if (this.index >= this.pool.length) {
            this.pool.push({start: -1, count: -1, z: -1});
        }
        var item = this.pool[this.index];
        this.list.push(item);
        this.index++;
        item.start = drawRange.start;
        item.count = drawRange.count;
        item.z = z;
    }

    public function reset():Void {
        this.list = [];
        this.index = 0;
    }
}

class BatchedMesh extends Mesh {

    public var isBatchedMesh:Bool;
    public var perObjectFrustumCulled:Bool;
    public var sortObjects:Bool;
    public var boundingBox:Box3;
    public var boundingSphere:Sphere;
    public var customSort:Dynamic;
    public var _drawRanges:Array<Dynamic>;
    public var _reservedRanges:Array<Dynamic>;
    public var _visibility:Array<Bool>;
    public var _active:Array<Bool>;
    public var _bounds:Array<Dynamic>;
    public var _maxGeometryCount:Int;
    public var _maxVertexCount:Int;
    public var _maxIndexCount:Int;
    public var _geometryInitialized:Bool;
    public var _geometryCount:Int;
    public var _multiDrawCounts:Int32Array;
    public var _multiDrawStarts:Int32Array;
    public var _multiDrawCount:Int;
    public var _multiDrawInstances:Int32Array;
    public var _visibilityChanged:Bool;
    public var _matricesTexture:DataTexture;
    public var _colorsTexture:DataTexture;

    static var ID_ATTR_NAME = "batchId";
    static var _matrix = new Matrix4();
    static var _invMatrixWorld = new Matrix4();
    static var _identityMatrix = new Matrix4();
    static var _projScreenMatrix = new Matrix4();
    static var _frustum = new Frustum();
    static var _box = new Box3();
    static var _sphere = new Sphere();
    static var _vector = new Vector3();
    static var _renderList = new MultiDrawRenderList();
    static var _mesh = new Mesh();
    static var _batchIntersects = [];

    public function new(maxGeometryCount:Int, maxVertexCount:Int, maxIndexCount:Int = maxVertexCount * 2, material:Dynamic) {
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
    }

    function _initMatricesTexture():Void {
        var size = Math.sqrt(this._maxGeometryCount * 4);
        size = Math.ceil(size / 4) * 4;
        size = Math.max(size, 4);

        var matricesArray = new Float32Array(size * size * 4);
        var matricesTexture = new DataTexture(matricesArray, size, size, RGBAFormat, FloatType);

        this._matricesTexture = matricesTexture;
    }

    function _initColorsTexture():Void {
        var size = Math.sqrt(this._maxGeometryCount);
        size = Math.ceil(size);

        var colorsArray = new Float32Array(size * size * 4);
        var colorsTexture = new DataTexture(colorsArray, size, size, RGBAFormat, FloatType);
        colorsTexture.colorSpace = ColorManagement.workingColorSpace;

        this._colorsTexture = colorsTexture;
    }

    function _initializeGeometry(reference:Dynamic):Void {
        var geometry = this.geometry;
        var maxVertexCount = this._maxVertexCount;
        var maxGeometryCount = this._maxGeometryCount;
        var maxIndexCount = this._maxIndexCount;

        if (!this._geometryInitialized) {
            for (attributeName in reference.attributes) {
                var srcAttribute = reference.getAttribute(attributeName);
                var array = srcAttribute.array;
                var itemSize = srcAttribute.itemSize;
                var normalized = srcAttribute.normalized;

                var dstArray = new array.constructor(maxVertexCount * itemSize);
                var dstAttribute = new BufferAttribute(dstArray, itemSize, normalized);

                geometry.setAttribute(attributeName, dstAttribute);
            }

            if (reference.getIndex() != null) {
                var indexArray = maxVertexCount > 65536 ? new Uint32Array(maxIndexCount) : new Uint16Array(maxIndexCount);
                geometry.setIndex(new BufferAttribute(indexArray, 1));
            }

            var idArray = maxGeometryCount > 65536 ? new Uint32Array(maxVertexCount) : new Uint16Array(maxVertexCount);
            geometry.setAttribute(ID_ATTR_NAME, new BufferAttribute(idArray, 1));

            this._geometryInitialized = true;
        }
    }

    function _validateGeometry(geometry:Dynamic):Void {
        if (geometry.getAttribute(ID_ATTR_NAME) != null) {
            throw new js.Error('BatchedMesh: Geometry cannot use attribute "' + ID_ATTR_NAME + '"');
        }

        var batchGeometry = this.geometry;
        if ((geometry.getIndex() != null) != (batchGeometry.getIndex() != null)) {
            throw new js.Error('BatchedMesh: All geometries must consistently have "index".');
        }

        for (attributeName in batchGeometry.attributes) {
            if (attributeName == ID_ATTR_NAME) continue;

            if (!geometry.hasAttribute(attributeName)) {
                throw new js.Error('BatchedMesh: Added geometry missing "' + attributeName + '". All geometries must have consistent attributes.');
            }

            var srcAttribute = geometry.getAttribute(attributeName);
            var dstAttribute = batchGeometry.getAttribute(attributeName);
            if (srcAttribute.itemSize != dstAttribute.itemSize || srcAttribute.normalized != dstAttribute.normalized) {
                throw new js.Error('BatchedMesh: All attributes must have a consistent itemSize and normalized value.');
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
        for (i in 0...geometryCount) {
            if (!active[i]) continue;

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
        for (i in 0...geometryCount) {
            if (!active[i]) continue;

            this.getMatrixAt(i, _matrix);
            this.getBoundingSphereAt(i, _sphere).applyMatrix4(_matrix);
            boundingSphere.union(_sphere);
        }
    }

    public function addGeometry(geometry:Dynamic, vertexCount:Int = -1, indexCount:Int = -1):Int {
        this._initializeGeometry(geometry);
        this._validateGeometry(geometry);

        if (this._geometryCount >= this._maxGeometryCount) {
            throw new js.Error('BatchedMesh: Maximum geometry count reached.');
        }

        var reservedRange = {vertexStart: -1, vertexCount: -1, indexStart: -1, indexCount: -1};
        var lastRange = null;
        var reservedRanges = this._reservedRanges;
        var drawRanges = this._drawRanges;
        var bounds = this._bounds;

        if (this._geometryCount != 0) {
            lastRange = reservedRanges[reservedRanges.length - 1];
        }

        reservedRange.vertexCount = vertexCount == -1 ? geometry.getAttribute("position").count : vertexCount;
        reservedRange.vertexStart = lastRange == null ? 0 : lastRange.vertexStart + lastRange.vertexCount;

        var index = geometry.getIndex();
        var hasIndex = index != null;
        if (hasIndex) {
            reservedRange.indexCount = indexCount == -1 ? index.count : indexCount;
            reservedRange.indexStart = lastRange == null ? 0 : lastRange.indexStart + lastRange.indexCount;
        } else {
            reservedRange.indexCount = 0;
            reservedRange.indexStart = 0;
        }

        reservedRanges.push(reservedRange);
        drawRanges.push({start: reservedRange.indexStart, count: reservedRange.indexCount});

        this._geometryCount++;
        this._visibilityChanged = true;
        this._active.push(true);

        for (attributeName in geometry.attributes) {
            if (attributeName == ID_ATTR_NAME) continue;

            var srcAttribute = geometry.getAttribute(attributeName);
            var dstAttribute = this.geometry.getAttribute(attributeName);
            dstAttribute.set(srcAttribute.array, reservedRange.vertexStart * srcAttribute.itemSize);
            dstAttribute.needsUpdate = true;
        }

        if (hasIndex) {
            var srcIndex = geometry.getIndex().array;
            var dstIndex = this.geometry.getIndex().array;
            for (i in 0...reservedRange.indexCount) {
                dstIndex[reservedRange.indexStart + i] = srcIndex[i] + reservedRange.vertexStart;
            }
            this.geometry.getIndex().needsUpdate = true;
        }

        var boundingBox = new Box3();
        var boundingSphere = new Sphere();
        geometry.computeBoundingBox();
        geometry.computeBoundingSphere();
        if (geometry.boundingBox != null) {
            boundingBox.copy(geometry.boundingBox);
        }
        if (geometry.boundingSphere != null) {
            boundingSphere.copy(geometry.boundingSphere);
        }

        bounds.push({box: boundingBox, sphere: boundingSphere});
        return this._geometryCount - 1;
    }
}