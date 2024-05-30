import BufferAttribute.BufferAttribute;
import BufferGeometry.BufferGeometry;
import DataTexture.DataTexture;
import FloatType.FloatType;
import Matrix4.Matrix4;
import Mesh.Mesh;
import RGBAFormat.RGBAFormat;
import ColorManagement.ColorManagement;
import Box3.Box3;
import Sphere.Sphere;
import Frustum.Frustum;
import Vector3.Vector3;

class MultiDrawRenderList {
  public var index:Int;
  public var pool:Array<{start:Int, count:Int, z:Int}>;
  public var list:Array<{start:Int, count:Int, z:Int}>;

  public function new() {
    this.index = 0;
    this.pool = [];
    this.list = [];
  }

  public function push(drawRange: {start:Int, count:Int}, z:Int) {
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

  public function reset() {
    this.list.length = 0;
    this.index = 0;
  }
}

class BatchedMesh extends Mesh {
  public var maxGeometryCount:Int;

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

  private function _initMatricesTexture() {
    // ...
  }

  private function _initColorsTexture() {
    // ...
  }

  private function _initializeGeometry(reference:BufferGeometry) {
    // ...
  }

  private function _validateGeometry(geometry:BufferGeometry) {
    // ...
  }

  public function setCustomSort(func:Dynamic) {
    this.customSort = func;
    return this;
  }

  public function computeBoundingBox() {
    // ...
  }

  public function computeBoundingSphere() {
    // ...
  }

  public function addGeometry(geometry:BufferGeometry, vertexCount:Int = -1, indexCount:Int = -1) {
    // ...
  }

  public function setGeometryAt(id:Int, geometry:BufferGeometry) {
    // ...
  }

  public function deleteGeometry(geometryId:Int) {
    // ...
  }

  public function getInstanceCountAt(id:Int) {
    // ...
  }

  public function setInstanceCountAt(id:Int, instanceCount:Int) {
    // ...
  }

  public function getBoundingBoxAt(id:Int, target:Box3) {
    // ...
  }

  public function getBoundingSphereAt(id:Int, target:Sphere) {
    // ...
  }

  public function setMatrixAt(geometryId:Int, matrix:Matrix4) {
    // ...
  }

  public function getMatrixAt(geometryId:Int, matrix:Matrix4) {
    // ...
  }

  public function setColorAt(geometryId:Int, color:Dynamic) {
    // ...
  }

  public function getColorAt(geometryId:Int, color:Dynamic) {
    // ...
  }

  public function setVisibleAt(geometryId:Int, value:Bool) {
    // ...
  }

  public function getVisibleAt(geometryId:Int) {
    // ...
  }

  public function raycast(raycaster:Dynamic, intersects:Array<Dynamic>) {
    // ...
  }

  public function copy(source:BatchedMesh) {
    // ...
  }

  public function dispose() {
    // ...
  }

  public function onBeforeRender(renderer:Dynamic, scene:Dynamic, camera:Dynamic, geometry:BufferGeometry, material:Dynamic, group:Dynamic) {
    // ...
  }

  public function onBeforeShadow(renderer:Dynamic, object:Dynamic, camera:Dynamic, shadowCamera:Dynamic, geometry:BufferGeometry, depthMaterial:Dynamic, group:Dynamic) {
    // ...
  }
}