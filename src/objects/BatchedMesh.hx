package three.objects;

import haxe.ds.Vector;
import three.math.Matrix4;
import three.math.Vector3;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.materials.Material;
import three.math.Box3;
import three.math.Sphere;
import three.math.Frustum;
import three.textures.DataTexture;
import three.constants.FloatType;
import three.constants.RGBAFormat;
import three.math.Color;
import three.math.ColorManagement;

class BatchedMesh extends Mesh {
    public var maxGeometryCount:Int;
    public var maxVertexCount:Int;
    public var maxIndexCount:Int;
    public var geometryInitialized:Bool;
    public var geometryCount:Int;
    public var multiDrawCounts:Vector<Int>;
    public var multiDrawStarts:Vector<Int>;
    public var multiDrawInstances:Vector<Int>;
    public var visibility:Vector<Bool>;
    public var active:Vector<Bool>;
    public var bounds:Array<{ box:Box3, sphere:Sphere, boxInitialized:Bool, sphereInitialized:Bool }>;
    public var drawRanges:Array<{ start:Int, count:Int }>;
    public var reservedRanges:Array<{ vertexStart:Int, vertexCount:Int, indexStart:Int, indexCount:Int }>;
    public var matricesTexture:DataTexture;
    public var colorsTexture:DataTexture;
    public var _renderList:MultiDrawRenderList;
    public var _mesh:Mesh;
    public var _vector:Vector3;
    public var _matrix:Matrix4;
    public var _invMatrixWorld:Matrix4;
    public var _identityMatrix:Matrix4;
    public var _projScreenMatrix:Matrix4;
    public var _frustum:Frustum;
    public var _box:Box3;
    public var _sphere:Sphere;
    public var _batchIntersects:Array<{ distance:Float, point:Vector3, face:Vector3, faceIndex:Int, object:Object3D }>;

    public function new(maxGeometryCount:Int, maxVertexCount:Int, maxIndexCount:Int, material:Material) {
        super(new BufferGeometry(), material);
        this.isBatchedMesh = true;
        this.perObjectFrustumCulled = true;
        this.sortObjects = true;
        this.boundingBox = null;
        this.boundingSphere = null;
        this.customSort = null;

        this.maxGeometryCount = maxGeometryCount;
        this.maxVertexCount = maxVertexCount;
        this.maxIndexCount = maxIndexCount;

        this._geometryInitialized = false;
        this._geometryCount = 0;
        this._multiDrawCounts = new Vector<Int>(maxGeometryCount);
        this._multiDrawStarts = new Vector<Int>(maxGeometryCount);
        this._multiDrawCount = 0;
        this._multiDrawInstances = null;
        this._visibilityChanged = true;

        this._matricesTexture = new DataTexture(new Float32Array(maxGeometryCount * 4 * 4), 4, 4, RGBAFormat, FloatType);
        this._colorsTexture = null;

        this._initMatricesTexture();

        this._renderList = new MultiDrawRenderList();
        this._mesh = new Mesh();
        this._vector = new Vector3();
        this._matrix = new Matrix4();
        this._invMatrixWorld = new Matrix4();
        this._identityMatrix = new Matrix4();
        this._projScreenMatrix = new Matrix4();
        this._frustum = new Frustum();
        this._box = new Box3();
        this._sphere = new Sphere();
        this._batchIntersects = [];

        this._reservedRanges = [];
        this._drawRanges = [];
        this._bounds = [];
        this._visibility = [];
        this._active = [];
    }

    // ...
}