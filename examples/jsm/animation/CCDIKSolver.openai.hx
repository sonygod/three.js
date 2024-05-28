package three.js.animation;

import three.js.BufferAttribute;
import three.js.BufferGeometry;
import three.js.Color;
import three.js.Line;
import three.js.LineBasicMaterial;
import three.js.Matrix4;
import three.js.Mesh;
import three.js.MeshBasicMaterial;
import three.js.Object3D;
import three.js.Quaternion;
import three.js.SphereGeometry;
import three.js.Vector3;

class CCDIKSolver {
  private var mesh:SkinnedMesh;
  private var iks:Array<Object>;

  private var _q:Quaternion;
  private var _targetPos:Vector3;
  private var _targetVec:Vector3;
  private var _effectorPos:Vector3;
  private var _effectorVec:Vector3;
  private var _linkPos:Vector3;
  private var _invLinkQ:Quaternion;
  private var _linkScale:Vector3;
  private var _axis:Vector3;
  private var _vector:Vector3;
  private var _matrix:Matrix4;

  public function new(mesh:SkinnedMesh, iks:Array<Object> = []) {
    this.mesh = mesh;
    this.iks = iks;
    _valid();

    _q = new Quaternion();
    _targetPos = new Vector3();
    _targetVec = new Vector3();
    _effectorPos = new Vector3();
    _effectorVec = new Vector3();
    _linkPos = new Vector3();
    _invLinkQ = new Quaternion();
    _linkScale = new Vector3();
    _axis = new Vector3();
    _vector = new Vector3();
    _matrix = new Matrix4();
  }

  public function update():CCDIKSolver {
    for (ik in iks) {
      updateOne(ik);
    }
    return this;
  }

  public function updateOne(ik:Object):CCDIKSolver {
    // implementation
    return this;
  }

  public function createHelper(sphereSize:Float = 0.25):CCDIKHelper {
    return new CCDIKHelper(this.mesh, this.iks, sphereSize);
  }

  private function _valid():Void {
    // implementation
  }
}

class CCDIKHelper extends Object3D {
  private var root:SkinnedMesh;
  private var iks:Array<Object>;
  private var sphereGeometry:SphereGeometry;
  private var targetSphereMaterial:MeshBasicMaterial;
  private var effectorSphereMaterial:MeshBasicMaterial;
  private var linkSphereMaterial:MeshBasicMaterial;
  private var lineMaterial:LineBasicMaterial;

  public function new(mesh:SkinnedMesh, iks:Array<Object> = [], sphereSize:Float = 0.25) {
    super();

    root = mesh;
    this.iks = iks;

    matrix.copyFrom(mesh.matrixWorld);
    matrixAutoUpdate = false;

    sphereGeometry = new SphereGeometry(sphereSize, 16, 8);

    targetSphereMaterial = new MeshBasicMaterial({
      color: new Color(0xff8888),
      depthTest: false,
      depthWrite: false,
      transparent: true
    });

    effectorSphereMaterial = new MeshBasicMaterial({
      color: new Color(0x88ff88),
      depthTest: false,
      depthWrite: false,
      transparent: true
    });

    linkSphereMaterial = new MeshBasicMaterial({
      color: new Color(0x8888ff),
      depthTest: false,
      depthWrite: false,
      transparent: true
    });

    lineMaterial = new LineBasicMaterial({
      color: new Color(0xff0000),
      depthTest: false,
      depthWrite: false,
      transparent: true
    });

    _init();
  }

  public function updateMatrixWorld(force:Bool = false):Void {
    // implementation
  }

  public function dispose():Void {
    // implementation
  }

  private function _init():Void {
    // implementation
  }
}