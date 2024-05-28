package three;

import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.textures.DataTexture;
import three.constants.FloatType;
import three.math.Matrix4;
import three.math.ColorManagement;
import three.math.Box3;
import three.math.Sphere;
import three.math.Frustum;
import three.math.Vector3;
import three.objects.Mesh;

class BatchedMesh extends Mesh {
    public var maxGeometryCount(get, null):Int;
    private var _maxGeometryCount:Int;
    private var _maxVertexCount:Int;
    private var _maxIndexCount:Int;
    private var isBatchedMesh:Bool = true;
    private var perObjectFrustumCulled:Bool = true;
    private var sortObjects:Bool = true;
    private var boundingBox:Box3;
    private var boundingSphere:Sphere;
    private var customSort:Void->Void;
    private var _drawRanges:Array_DRAW_RANGE = [];
    private var _reservedRanges:Array_RESERVED_RANGE = [];
    private var _visibility:Array<Bool> = [];
    private var _active:Array<Bool> = [];
    private var _bounds:Array<BATCH_BOUNDS> = [];
    private var _geometryInitialized:Bool = false;
    private var _geometryCount:Int = 0;
    private var _multiDrawCounts:Array<Int> = [];
    private var _multiDrawStarts:Array<Int> = [];
    private var _multiDrawCount:Int = 0;
    private var _multiDrawInstances:Array<Int> = null;
    private var _visibilityChanged:Bool = true;
    private var _matricesTexture:DataTexture;
    private var _colorsTexture:DataTexture = null;

    public function new(maxGeometryCount:Int, maxVertexCount:Int, maxIndexCount:Int, material:Material) {
        super(new BufferGeometry(), material);
        _maxGeometryCount = maxGeometryCount;
        _maxVertexCount = maxVertexCount;
        _maxIndexCount = maxIndexCount;
        _initMatricesTexture();
        _initColorsTexture();
    }

    private function _initMatricesTexture():Void {
        var size:Int = Math.ceil(Math.sqrt(_maxGeometryCount * 4));
        size = Math.max(size, 4);
        var matricesArray:Array<Float> = new Array<Float>(size * size * 4);
        _matricesTexture = new DataTexture(matricesArray, size, size, RGBAFormat, FloatType);
    }

    private function _initColorsTexture():Void {
        var size:Int = Math.ceil(Math.sqrt(_maxGeometryCount));
        size = Math.max(size, 4);
        var colorsArray:Array<Float> = new Array<Float>(size * size * 4);
        _colorsTexture = new DataTexture(colorsArray, size, size, RGBAFormat, FloatType);
    }

    // ... rest of the code ...

    // copied from the original code
}