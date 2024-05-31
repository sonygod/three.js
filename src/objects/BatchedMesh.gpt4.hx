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
            this.pool.push({
                start: -1,
                count: -1,
                z: -1
            });
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
    private var _matricesTexture:DataTexture;
    private var _colorsTexture:DataTexture;
    private var _drawRanges:Array<Dynamic> = [];
    private var _reservedRanges:Array<Dynamic> = [];
    private var _visibility:Array<Bool> = [];
    private var _active:Array<Bool> = [];
    private var _bounds:Array<Dynamic> = [];
    private var customSort:Dynamic = null;

    public function new(maxGeometryCount:Int, maxVertexCount:Int, ?maxIndexCount:Int, material:Dynamic) {
        super(new BufferGeometry(), material);

        this.isBatchedMesh = true;
        this.perObjectFrustumCulled = true;
        this.sortObjects = true;
        this.boundingBox = null;
        this.boundingSphere = null;

        this._maxGeometryCount = maxGeometryCount;
        this._maxVertexCount = maxVertexCount;
        this._maxIndexCount = maxIndexCount == null ? maxVertexCount * 2 : maxIndexCount;

        this._multiDrawCounts = new Int32Array(maxGeometryCount);
        this._multiDrawStarts = new Int32Array(maxGeometryCount);

        this._initMatricesTexture();
    }

    private function _initMatricesTexture():Void {
        var size = Math.sqrt(this._maxGeometryCount * 4);
        size = Math.ceil(size / 4) * 4;
        size = Math.max(size, 4);

        var matricesArray = new Float32Array(size * size * 4);
        this._matricesTexture = new DataTexture(matricesArray, size, size, RGBAFormat, FloatType);
    }

    private function _initColorsTexture():Void {
        var size = Math.sqrt(this._maxGeometryCount);
        size = Math.ceil(size);

        var colorsArray = new Float32Array(size * size * 4);
        this._colorsTexture = new DataTexture(colorsArray, size, size, RGBAFormat, FloatType);
        this._colorsTexture.colorSpace = ColorManagement.workingColorSpace;
    }

    private function _initializeGeometry(reference:Dynamic):Void {
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
            geometry.setAttribute("batchId", new BufferAttribute(idArray, 1));

            this._geometryInitialized = true;
        }
    }

    private function _validateGeometry(geometry:Dynamic):Void {
        if (geometry.getAttribute("batchId") != null) {
            throw "BatchedMesh: Geometry cannot use attribute \"batchId\"";
        }

        var batchGeometry = this.geometry;
        if (geometry.getIndex() != null != (batchGeometry.getIndex() != null)) {
            throw "BatchedMesh: All geometries must consistently have \"index\".";
        }

        for (attributeName in batchGeometry.attributes) {
            if (attributeName == "batchId") {
                continue;
            }
            if (!geometry.hasAttribute(attributeName)) {
                throw "BatchedMesh: Added geometry missing \"" + attributeName + "\". All geometries must have consistent attributes.";
            }

            var srcAttribute = geometry.getAttribute(attributeName);
            var dstAttribute = batchGeometry.getAttribute(attributeName);
            if (srcAttribute.itemSize != dstAttribute.itemSize || srcAttribute.normalized != dstAttribute.normalized) {
                throw "BatchedMesh: All attributes must have a consistent itemSize and normalized value.";
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
            throw "BatchedMesh: Maximum geometry count reached.";
        }

        var reservedRange = {
            vertexStart: -1,
            vertexCount: -1,
            indexStart: -1,
            indexCount: -1
        };

        var lastRange = this._reservedRanges.length != 0 ? this._reservedRanges[this._reservedRanges.length - 1] : null;

        reservedRange.vertexCount = vertexCount == -1 ? geometry.getAttribute("position").count : vertexCount;
        reservedRange.vertexStart = lastRange == null ? 0 : lastRange.vertexStart + lastRange.vertexCount;

        var index = geometry.getIndex();
        var hasIndex = index != null;

        if (hasIndex) {
            reservedRange.indexCount = indexCount == -1 ? index.count : indexCount;
            reservedRange.indexStart = lastRange == null ? 0 : lastRange.indexStart + lastRange.indexCount;
        }

        if ((reservedRange.indexStart != -1 && reservedRange.indexStart + reservedRange.indexCount > this._maxIndexCount) ||
            (reservedRange.vertexStart + reservedRange.vertexCount > this._maxVertexCount)) {
            throw "BatchedMesh: Reserved space request exceeds the maximum buffer size.";
        }

        this._visibility.push(true);
        this._active.push(true);

        var geometryId = this._geometryCount++;
        var matricesArray = this._matricesTexture.image.data;
        _identityMatrix.toArray(matricesArray, geometryId * 16);
        this._matricesTexture.needsUpdate = true;

        this._reservedRanges.push(reservedRange);
        this._drawRanges.push({
            start: hasIndex ? reservedRange.indexStart : reservedRange.vertexStart,
            count: -1
        });
        this._bounds.push({
            boxInitialized: false,
            box: new Box3(),
            sphereInitialized: false,
            sphere: new Sphere()
        });

        var idAttribute = this.geometry.getAttribute("batchId");
        for (i in 0...reservedRange.vertexCount) {
            idAttribute.setX(reservedRange.vertexStart + i, geometryId);
        }

        return geometryId;
    }

    public function updateGeometry(geometryId:Int, geometry:Dynamic):Void {
        if (geometryId >= this._geometryCount) {
            throw "BatchedMesh: Geometry ID out of range.";
        }

        this._validateGeometry(geometry);

        var attributes = geometry.attributes;
        var index = geometry.getIndex();
        var drawRange = this._drawRanges[geometryId];
        var reservedRange = this._reservedRanges[geometryId];
        var batchGeometry = this.geometry;

        var vertexStart = reservedRange.vertexStart;
        var indexStart = reservedRange.indexStart;
        var maxVertexCount = reservedRange.vertexCount;
        var maxIndexCount = reservedRange.indexCount;

        for (attributeName in attributes) {
            var srcAttribute = geometry.getAttribute(attributeName);
            var dstAttribute = batchGeometry.getAttribute(attributeName);
            for (i in 0...srcAttribute.count) {
                dstAttribute.setXYZW(vertexStart + i, srcAttribute.getX(i), srcAttribute.getY(i), srcAttribute.getZ(i), srcAttribute.getW(i));
            }
            dstAttribute.needsUpdate = true;
        }

        if (index != null) {
            var dstIndex = batchGeometry.getIndex();
            for (i in 0...index.count) {
                dstIndex.setX(indexStart + i, index.getX(i) + vertexStart);
            }
            dstIndex.needsUpdate = true;
            drawRange.count = index.count;
        } else {
            drawRange.count = geometry.getAttribute("position").count;
        }

        var boundInfo = this._bounds[geometryId];
        boundInfo.boxInitialized = false;
        boundInfo.sphereInitialized = false;
    }

    public function removeGeometry(geometryId:Int):Void {
        if (geometryId >= this._geometryCount) {
            throw "BatchedMesh: Geometry ID out of range.";
        }

        this._visibility[geometryId] = false;
        this._active[geometryId] = false;
        this._visibilityChanged = true;

        var matricesArray = this._matricesTexture.image.data;
        _identityMatrix.toArray(matricesArray, geometryId * 16);
        this._matricesTexture.needsUpdate = true;
    }

    public function setMatrixAt(geometryId:Int, matrix:Matrix4):Void {
        var matricesArray = this._matricesTexture.image.data;
        matrix.toArray(matricesArray, geometryId * 16);
        this._matricesTexture.needsUpdate = true;
    }

    public function getMatrixAt(geometryId:Int, matrix:Matrix4):Matrix4 {
        var matricesArray = this._matricesTexture.image.data;
        return matrix.fromArray(matricesArray, geometryId * 16);
    }

    public function setColorAt(geometryId:Int, color:Color):Void {
        if (this._colorsTexture == null) {
            this._initColorsTexture();
        }

        var colorsArray = this._colorsTexture.image.data;
        color.toArray(colorsArray, geometryId * 4);
        this._colorsTexture.needsUpdate = true;
    }

    public function getColorAt(geometryId:Int, color:Color):Color {
        if (this._colorsTexture == null) {
            this._initColorsTexture();
        }

        var colorsArray = this._colorsTexture.image.data;
        return color.fromArray(colorsArray, geometryId * 4);
    }

    public function getBoundingBoxAt(geometryId:Int, target:Box3):Box3 {
        var bounds = this._bounds[geometryId];
        if (!bounds.boxInitialized) {
            this.geometry.computeBoundingBox();
            bounds.box.copy(this.geometry.boundingBox);
            bounds.boxInitialized = true;
        }
        return target.copy(bounds.box);
    }

    public function getBoundingSphereAt(geometryId:Int, target:Sphere):Sphere {
        var bounds = this._bounds[geometryId];
        if (!bounds.sphereInitialized) {
            this.geometry.computeBoundingSphere();
            bounds.sphere.copy(this.geometry.boundingSphere);
            bounds.sphereInitialized = true;
        }
        return target.copy(bounds.sphere);
    }

    public function setVisibilityAt(geometryId:Int, visible:Bool):Void {
        if (geometryId >= this._geometryCount) {
            throw "BatchedMesh: Geometry ID out of range.";
        }

        if (this._visibility[geometryId] != visible) {
            this._visibility[geometryId] = visible;
            this._visibilityChanged = true;
        }
    }

    public function isVisible(geometryId:Int):Bool {
        return this._visibility[geometryId];
    }

    public function isActive(geometryId:Int):Bool {
        return this._active[geometryId];
    }

    public function onBeforeRender(renderList:MultiDrawRenderList, frustum:Frustum):Void {
        if (this._visibilityChanged) {
            this._multiDrawCount = 0;

            for (geometryId in 0...this._geometryCount) {
                if (!this._visibility[geometryId]) continue;
                if (this.perObjectFrustumCulled && !frustum.intersectsBox(this.getBoundingBoxAt(geometryId, _box))) continue;

                var drawRange = this._drawRanges[geometryId];
                renderList.push(drawRange, _vector.setFromMatrixPosition(this.getMatrixAt(geometryId, _matrix)).applyMatrix4(_modelViewMatrix).z);

                this._multiDrawStarts[this._multiDrawCount] = drawRange.start;
                this._multiDrawCounts[this._multiDrawCount] = drawRange.count;
                if (this._multiDrawInstances != null) this._multiDrawInstances[this._multiDrawCount] = geometryId;
                this._multiDrawCount++;
            }

            this._visibilityChanged = false;
        }

        if (this.sortObjects && this.customSort != null) {
            this.customSort(renderList);
        }
    }

}