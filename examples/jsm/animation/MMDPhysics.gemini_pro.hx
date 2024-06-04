import three.core.Object3D;
import three.core.Bone;
import three.math.Vector3;
import three.math.Quaternion;
import three.math.Euler;
import three.math.Matrix4;
import three.geometries.BoxGeometry;
import three.geometries.SphereGeometry;
import three.geometries.CapsuleGeometry;
import three.materials.MeshBasicMaterial;
import three.core.Mesh;
import three.math.Color;
import three.core.SkinnedMesh;

/**
 * Dependencies
 *  - Ammo.js https://github.com/kripken/ammo.js
 *
 * MMDPhysics calculates physics with Ammo(Bullet based JavaScript Physics engine)
 * for MMD model loaded by MMDLoader.
 *
 * TODO
 *  - Physics in Worker
 */

@:jsRequire("ammo.js")
extern class Ammo {
  static btDefaultCollisionConfiguration():Dynamic;
  static btCollisionDispatcher(config:Dynamic):Dynamic;
  static btDbvtBroadphase():Dynamic;
  static btSequentialImpulseConstraintSolver():Dynamic;
  static btDiscreteDynamicsWorld(dispatcher:Dynamic, cache:Dynamic, solver:Dynamic, config:Dynamic):Dynamic;
  static btSphereShape(radius:Float):Dynamic;
  static btBoxShape(halfExtents:Dynamic):Dynamic;
  static btCapsuleShape(radius:Float, height:Float):Dynamic;
  static btRigidBodyConstructionInfo(mass:Float, motionState:Dynamic, shape:Dynamic, localInertia:Dynamic):Dynamic;
  static btTransform():Dynamic;
  static btQuaternion():Dynamic;
  static btVector3():Dynamic;
  static btGeneric6DofSpringConstraint(bodyA:Dynamic, bodyB:Dynamic, frameInA:Dynamic, frameInB:Dynamic, useLinearReferenceFrameA:Bool):Dynamic;
  static btDefaultMotionState(startTransform:Dynamic):Dynamic;
}

class RigidBodyParam {
  public var shapeType:Int;
  public var width:Float;
  public var height:Float;
  public var depth:Float;
  public var position:Array<Float>;
  public var rotation:Array<Float>;
  public var boneIndex:Int;
  public var groupIndex:Int;
  public var groupTarget:Int;
  public var type:Int;
  public var weight:Float;
  public var friction:Float;
  public var restitution:Float;
  public var positionDamping:Float;
  public var rotationDamping:Float;
  public var springPosition:Array<Float>;
  public var springRotation:Array<Float>;

  public function new(shapeType:Int, width:Float, height:Float, depth:Float, position:Array<Float>, rotation:Array<Float>, boneIndex:Int, groupIndex:Int, groupTarget:Int, type:Int, weight:Float, friction:Float, restitution:Float, positionDamping:Float, rotationDamping:Float, springPosition:Array<Float>, springRotation:Array<Float>) {
    this.shapeType = shapeType;
    this.width = width;
    this.height = height;
    this.depth = depth;
    this.position = position;
    this.rotation = rotation;
    this.boneIndex = boneIndex;
    this.groupIndex = groupIndex;
    this.groupTarget = groupTarget;
    this.type = type;
    this.weight = weight;
    this.friction = friction;
    this.restitution = restitution;
    this.positionDamping = positionDamping;
    this.rotationDamping = rotationDamping;
    this.springPosition = springPosition;
    this.springRotation = springRotation;
  }
}

class ConstraintParam {
  public var rigidBodyIndex1:Int;
  public var rigidBodyIndex2:Int;
  public var position:Array<Float>;
  public var rotation:Array<Float>;
  public var translationLimitation1:Array<Float>;
  public var translationLimitation2:Array<Float>;
  public var rotationLimitation1:Array<Float>;
  public var rotationLimitation2:Array<Float>;
  public var springPosition:Array<Float>;
  public var springRotation:Array<Float>;

  public function new(rigidBodyIndex1:Int, rigidBodyIndex2:Int, position:Array<Float>, rotation:Array<Float>, translationLimitation1:Array<Float>, translationLimitation2:Array<Float>, rotationLimitation1:Array<Float>, rotationLimitation2:Array<Float>, springPosition:Array<Float>, springRotation:Array<Float>) {
    this.rigidBodyIndex1 = rigidBodyIndex1;
    this.rigidBodyIndex2 = rigidBodyIndex2;
    this.position = position;
    this.rotation = rotation;
    this.translationLimitation1 = translationLimitation1;
    this.translationLimitation2 = translationLimitation2;
    this.rotationLimitation1 = rotationLimitation1;
    this.rotationLimitation2 = rotationLimitation2;
    this.springPosition = springPosition;
    this.springRotation = springRotation;
  }
}

class MMDPhysics {
  public var mesh:SkinnedMesh;
  public var bodies:Array<RigidBody>;
  public var constraints:Array<Constraint>;
  public var manager:ResourceManager;
  public var world:Dynamic;
  public var unitStep:Float;
  public var maxStepNum:Int;
  public var gravity:Vector3;

  public function new(mesh:SkinnedMesh, rigidBodyParams:Array<RigidBodyParam>, constraintParams:Array<ConstraintParam> = [], params:Dynamic = null) {
    if (untyped !js.Lib.exists("Ammo")) {
      throw new Error("THREE.MMDPhysics: Import ammo.js https://github.com/kripken/ammo.js");
    }

    this.manager = new ResourceManager();
    this.mesh = mesh;
    this.unitStep = (params.unitStep != null) ? params.unitStep : 1 / 65;
    this.maxStepNum = (params.maxStepNum != null) ? params.maxStepNum : 3;
    this.gravity = new Vector3(0, -9.8 * 10, 0);

    if (params.gravity != null) this.gravity.copy(params.gravity);

    this.world = (params.world != null) ? params.world : null;

    this.bodies = [];
    this.constraints = [];

    this._init(mesh, rigidBodyParams, constraintParams);
  }

  public function update(delta:Float):MMDPhysics {
    var manager = this.manager;
    var mesh = this.mesh;

    var isNonDefaultScale = false;
    var position = manager.allocThreeVector3();
    var quaternion = manager.allocThreeQuaternion();
    var scale = manager.allocThreeVector3();

    mesh.matrixWorld.decompose(position, quaternion, scale);

    if (scale.x != 1 || scale.y != 1 || scale.z != 1) {
      isNonDefaultScale = true;
    }

    var parent;

    if (isNonDefaultScale) {
      parent = mesh.parent;

      if (parent != null) mesh.parent = null;

      scale.copy(this.mesh.scale);

      mesh.scale.set(1, 1, 1);
      mesh.updateMatrixWorld(true);
    }

    this._updateRigidBodies();
    this._stepSimulation(delta);
    this._updateBones();

    if (isNonDefaultScale) {
      if (parent != null) mesh.parent = parent;

      mesh.scale.copy(scale);
    }

    manager.freeThreeVector3(scale);
    manager.freeThreeQuaternion(quaternion);
    manager.freeThreeVector3(position);

    return this;
  }

  public function reset():MMDPhysics {
    for (i in 0...this.bodies.length) {
      this.bodies[i].reset();
    }

    return this;
  }

  public function warmup(cycles:Int):MMDPhysics {
    for (i in 0...cycles) {
      this.update(1 / 60);
    }

    return this;
  }

  public function setGravity(gravity:Vector3):MMDPhysics {
    this.world.setGravity(new Ammo.btVector3(gravity.x, gravity.y, gravity.z));
    this.gravity.copy(gravity);

    return this;
  }

  public function createHelper():MMDPhysicsHelper {
    return new MMDPhysicsHelper(this.mesh, this);
  }

  private function _init(mesh:SkinnedMesh, rigidBodyParams:Array<RigidBodyParam>, constraintParams:Array<ConstraintParam>) {
    var manager = this.manager;

    var parent = mesh.parent;

    if (parent != null) mesh.parent = null;

    var currentPosition = manager.allocThreeVector3();
    var currentQuaternion = manager.allocThreeQuaternion();
    var currentScale = manager.allocThreeVector3();

    currentPosition.copy(mesh.position);
    currentQuaternion.copy(mesh.quaternion);
    currentScale.copy(mesh.scale);

    mesh.position.set(0, 0, 0);
    mesh.quaternion.set(0, 0, 0, 1);
    mesh.scale.set(1, 1, 1);

    mesh.updateMatrixWorld(true);

    if (this.world == null) {
      this.world = this._createWorld();
      this.setGravity(this.gravity);
    }

    this._initRigidBodies(rigidBodyParams);
    this._initConstraints(constraintParams);

    if (parent != null) mesh.parent = parent;

    mesh.position.copy(currentPosition);
    mesh.quaternion.copy(currentQuaternion);
    mesh.scale.copy(currentScale);

    mesh.updateMatrixWorld(true);

    this.reset();

    manager.freeThreeVector3(currentPosition);
    manager.freeThreeQuaternion(currentQuaternion);
    manager.freeThreeVector3(currentScale);
  }

  private function _createWorld():Dynamic {
    var config = new Ammo.btDefaultCollisionConfiguration();
    var dispatcher = new Ammo.btCollisionDispatcher(config);
    var cache = new Ammo.btDbvtBroadphase();
    var solver = new Ammo.btSequentialImpulseConstraintSolver();
    var world = new Ammo.btDiscreteDynamicsWorld(dispatcher, cache, solver, config);
    return world;
  }

  private function _initRigidBodies(rigidBodies:Array<RigidBodyParam>) {
    for (i in 0...rigidBodies.length) {
      this.bodies.push(new RigidBody(this.mesh, this.world, rigidBodies[i], this.manager));
    }
  }

  private function _initConstraints(constraints:Array<ConstraintParam>) {
    for (i in 0...constraints.length) {
      var params = constraints[i];
      var bodyA = this.bodies[params.rigidBodyIndex1];
      var bodyB = this.bodies[params.rigidBodyIndex2];
      this.constraints.push(new Constraint(this.mesh, this.world, bodyA, bodyB, params, this.manager));
    }
  }

  private function _stepSimulation(delta:Float) {
    var unitStep = this.unitStep;
    var stepTime = delta;
    var maxStepNum = (delta / unitStep).floor() + 1;

    if (stepTime < unitStep) {
      stepTime = unitStep;
      maxStepNum = 1;
    }

    if (maxStepNum > this.maxStepNum) {
      maxStepNum = this.maxStepNum;
    }

    this.world.stepSimulation(stepTime, maxStepNum, unitStep);
  }

  private function _updateRigidBodies() {
    for (i in 0...this.bodies.length) {
      this.bodies[i].updateFromBone();
    }
  }

  private function _updateBones() {
    for (i in 0...this.bodies.length) {
      this.bodies[i].updateBone();
    }
  }
}

class ResourceManager {
  public var threeVector3s:Array<Vector3>;
  public var threeMatrix4s:Array<Matrix4>;
  public var threeQuaternions:Array<Quaternion>;
  public var threeEulers:Array<Euler>;
  public var transforms:Array<Dynamic>;
  public var quaternions:Array<Dynamic>;
  public var vector3s:Array<Dynamic>;

  public function new() {
    this.threeVector3s = [];
    this.threeMatrix4s = [];
    this.threeQuaternions = [];
    this.threeEulers = [];
    this.transforms = [];
    this.quaternions = [];
    this.vector3s = [];
  }

  public function allocThreeVector3():Vector3 {
    return (this.threeVector3s.length > 0) ? this.threeVector3s.pop() : new Vector3();
  }

  public function freeThreeVector3(v:Vector3) {
    this.threeVector3s.push(v);
  }

  public function allocThreeMatrix4():Matrix4 {
    return (this.threeMatrix4s.length > 0) ? this.threeMatrix4s.pop() : new Matrix4();
  }

  public function freeThreeMatrix4(m:Matrix4) {
    this.threeMatrix4s.push(m);
  }

  public function allocThreeQuaternion():Quaternion {
    return (this.threeQuaternions.length > 0) ? this.threeQuaternions.pop() : new Quaternion();
  }

  public function freeThreeQuaternion(q:Quaternion) {
    this.threeQuaternions.push(q);
  }

  public function allocThreeEuler():Euler {
    return (this.threeEulers.length > 0) ? this.threeEulers.pop() : new Euler();
  }

  public function freeThreeEuler(e:Euler) {
    this.threeEulers.push(e);
  }

  public function allocTransform():Dynamic {
    return (this.transforms.length > 0) ? this.transforms.pop() : new Ammo.btTransform();
  }

  public function freeTransform(t:Dynamic) {
    this.transforms.push(t);
  }

  public function allocQuaternion():Dynamic {
    return (this.quaternions.length > 0) ? this.quaternions.pop() : new Ammo.btQuaternion();
  }

  public function freeQuaternion(q:Dynamic) {
    this.quaternions.push(q);
  }

  public function allocVector3():Dynamic {
    return (this.vector3s.length > 0) ? this.vector3s.pop() : new Ammo.btVector3();
  }

  public function freeVector3(v:Dynamic) {
    this.vector3s.push(v);
  }

  public function setIdentity(t:Dynamic) {
    t.setIdentity();
  }

  public function getBasis(t:Dynamic):Dynamic {
    var q = this.allocQuaternion();
    t.getBasis().getRotation(q);
    return q;
  }

  public function getBasisAsMatrix3(t:Dynamic):Array<Float> {
    var q = this.getBasis(t);
    var m = this.quaternionToMatrix3(q);
    this.freeQuaternion(q);
    return m;
  }

  public function getOrigin(t:Dynamic):Dynamic {
    return t.getOrigin();
  }

  public function setOrigin(t:Dynamic, v:Dynamic) {
    t.getOrigin().setValue(v.x(), v.y(), v.z());
  }

  public function copyOrigin(t1:Dynamic, t2:Dynamic) {
    var o = t2.getOrigin();
    this.setOrigin(t1, o);
  }

  public function setBasis(t:Dynamic, q:Dynamic) {
    t.setRotation(q);
  }

  public function setBasisFromMatrix3(t:Dynamic, m:Array<Float>) {
    var q = this.matrix3ToQuaternion(m);
    this.setBasis(t, q);
    this.freeQuaternion(q);
  }

  public function setOriginFromArray3(t:Dynamic, a:Array<Float>) {
    t.getOrigin().setValue(a[0], a[1], a[2]);
  }

  public function setOriginFromThreeVector3(t:Dynamic, v:Vector3) {
    t.getOrigin().setValue(v.x, v.y, v.z);
  }

  public function setBasisFromArray3(t:Dynamic, a:Array<Float>) {
    var thQ = this.allocThreeQuaternion();
    var thE = this.allocThreeEuler();
    thE.set(a[0], a[1], a[2]);
    this.setBasisFromThreeQuaternion(t, thQ.setFromEuler(thE));

    this.freeThreeEuler(thE);
    this.freeThreeQuaternion(thQ);
  }

  public function setBasisFromThreeQuaternion(t:Dynamic, a:Quaternion) {
    var q = this.allocQuaternion();

    q.setX(a.x);
    q.setY(a.y);
    q.setZ(a.z);
    q.setW(a.w);
    this.setBasis(t, q);

    this.freeQuaternion(q);
  }

  public function multiplyTransforms(t1:Dynamic, t2:Dynamic):Dynamic {
    var t = this.allocTransform();
    this.setIdentity(t);

    var m1 = this.getBasisAsMatrix3(t1);
    var m2 = this.getBasisAsMatrix3(t2);

    var o1 = this.getOrigin(t1);
    var o2 = this.getOrigin(t2);

    var v1 = this.multiplyMatrix3ByVector3(m1, o2);
    var v2 = this.addVector3(v1, o1);
    this.setOrigin(t, v2);

    var m3 = this.multiplyMatrices3(m1, m2);
    this.setBasisFromMatrix3(t, m3);

    this.freeVector3(v1);
    this.freeVector3(v2);

    return t;
  }

  public function inverseTransform(t:Dynamic):Dynamic {
    var t2 = this.allocTransform();

    var m1 = this.getBasisAsMatrix3(t);
    var o = this.getOrigin(t);

    var m2 = this.transposeMatrix3(m1);
    var v1 = this.negativeVector3(o);
    var v2 = this.multiplyMatrix3ByVector3(m2, v1);

    this.setOrigin(t2, v2);
    this.setBasisFromMatrix3(t2, m2);

    this.freeVector3(v1);
    this.freeVector3(v2);

    return t2;
  }

  public function multiplyMatrices3(m1:Array<Float>, m2:Array<Float>):Array<Float> {
    var m3 = [];

    var v10 = this.rowOfMatrix3(m1, 0);
    var v11 = this.rowOfMatrix3(m1, 1);
    var v12 = this.rowOfMatrix3(m1, 2);

    var v20 = this.columnOfMatrix3(m2, 0);
    var v21 = this.columnOfMatrix3(m2, 1);
    var v22 = this.columnOfMatrix3(m2, 2);

    m3[0] = this.dotVectors3(v10, v20);
    m3[1] = this.dotVectors3(v10, v21);
    m3[2] = this.dotVectors3(v10, v22);
    m3[3] = this.dotVectors3(v11, v20);
    m3[4] = this.dotVectors3(v11, v21);
    m3[5] = this.dotVectors3(v11, v22);
    m3[6] = this.dotVectors3(v12, v20);
    m3[7] = this.dotVectors3(v12, v21);
    m3[8] = this.dotVectors3(v12, v22);

    this.freeVector3(v10);
    this.freeVector3(v11);
    this.freeVector3(v12);
    this.freeVector3(v20);
    this.freeVector3(v21);
    this.freeVector3(v22);

    return m3;
  }

  public function addVector3(v1:Dynamic, v2:Dynamic):Dynamic {
    var v = this.allocVector3();
    v.setValue(v1.x() + v2.x(), v1.y() + v2.y(), v1.z() + v2.z());
    return v;
  }

  public function dotVectors3(v1:Dynamic, v2:Dynamic):Float {
    return v1.x() * v2.x() + v1.y() * v2.y() + v1.z() * v2.z();
  }

  public function rowOfMatrix3(m:Array<Float>, i:Int):Dynamic {
    var v = this.allocVector3();
    v.setValue(m[i * 3 + 0], m[i * 3 + 1], m[i * 3 + 2]);
    return v;
  }

  public function columnOfMatrix3(m:Array<Float>, i:Int):Dynamic {
    var v = this.allocVector3();
    v.setValue(m[i + 0], m[i + 3], m[i + 6]);
    return v;
  }

  public function negativeVector3(v:Dynamic):Dynamic {
    var v2 = this.allocVector3();
    v2.setValue(-v.x(), -v.y(), -v.z());
    return v2;
  }

  public function multiplyMatrix3ByVector3(m:Array<Float>, v:Dynamic):Dynamic {
    var v4 = this.allocVector3();

    var v0 = this.rowOfMatrix3(m, 0);
    var v1 = this.rowOfMatrix3(m, 1);
    var v2 = this.rowOfMatrix3(m, 2);
    var x = this.dotVectors3(v0, v);
    var y = this.dotVectors3(v1, v);
    var z = this.dotVectors3(v2, v);

    v4.setValue(x, y, z);

    this.freeVector3(v0);
    this.freeVector3(v1);
    this.freeVector3(v2);

    return v4;
  }

  public function transposeMatrix3(m:Array<Float>):Array<Float> {
    var m2 = [];
    m2[0] = m[0];
    m2[1] = m[3];
    m2[2] = m[6];
    m2[3] = m[1];
    m2[4] = m[4];
    m2[5] = m[7];
    m2[6] = m[2];
    m2[7] = m[5];
    m2[8] = m[8];
    return m2;
  }

  public function quaternionToMatrix3(q:Dynamic):Array<Float> {
    var m = [];

    var x = q.x();
    var y = q.y();
    var z = q.z();
    var w = q.w();

    var xx = x * x;
    var yy = y * y;
    var zz = z * z;

    var xy = x * y;
    var yz = y * z;
    var zx = z * x;

    var xw = x * w;
    var yw = y * w;
    var zw = z * w;

    m[0] = 1 - 2 * (yy + zz);
    m[1] = 2 * (xy - zw);
    m[2] = 2 * (zx + yw);
    m[3] = 2 * (xy + zw);
    m[4] = 1 - 2 * (zz + xx);
    m[5] = 2 * (yz - xw);
    m[6] = 2 * (zx - yw);
    m[7] = 2 * (yz + xw);
    m[8] = 1 - 2 * (xx + yy);

    return m;
  }

  public function matrix3ToQuaternion(m:Array<Float>):Dynamic {
    var t = m[0] + m[4] + m[8];
    var s:Float, x:Float, y:Float, z:Float, w:Float;

    if (t > 0) {
      s = Math.sqrt(t + 1.0) * 2;
      w = 0.25 * s;
      x = (m[7] - m[5]) / s;
      y = (m[2] - m[6]) / s;
      z = (m[3] - m[1]) / s;
    } else if ((m[0] > m[4]) && (m[0] > m[8])) {
      s = Math.sqrt(1.0 + m[0] - m[4] - m[8]) * 2;
      w = (m[7] - m[5]) / s;
      x = 0.25 * s;
      y = (m[1] + m[3]) / s;
      z = (m[2] + m[6]) / s;
    } else if (m[4] > m[8]) {
      s = Math.sqrt(1.0 + m[4] - m[0] - m[8]) * 2;
      w = (m[2] - m[6]) / s;
      x = (m[1] + m[3]) / s;
      y = 0.25 * s;
      z = (m[5] + m[7]) / s;
    } else {
      s = Math.sqrt(1.0 + m[8] - m[0] - m[4]) * 2;
      w = (m[3] - m[1]) / s;
      x = (m[2] + m[6]) / s;
      y = (m[5] + m[7]) / s;
      z = 0.25 * s;
    }

    var q = this.allocQuaternion();
    q.setX(x);
    q.setY(y);
    q.setZ(z);
    q.setW(w);
    return q;
  }
}

class RigidBody {
  public var mesh:SkinnedMesh;
  public var world:Dynamic;
  public var params:RigidBodyParam;
  public var manager:ResourceManager;
  public var body:Dynamic;
  public var bone:Bone;
  public var boneOffsetForm:Dynamic;
  public var boneOffsetFormInverse:Dynamic;

  public function new(mesh:SkinnedMesh, world:Dynamic, params:RigidBodyParam, manager:ResourceManager) {
    this.mesh = mesh;
    this.world = world;
    this.params = params;
    this.manager = manager;

    this.body = null;
    this.bone = null;
    this.boneOffsetForm = null;
    this.boneOffsetFormInverse = null;

    this._init();
  }

  public function reset():RigidBody {
    this._setTransformFromBone();
    return this;
  }

  public function updateFromBone():RigidBody {
    if (this.params.boneIndex != -1 && this.params.type == 0) {
      this._setTransformFromBone();
    }

    return this;
  }

  public function updateBone():RigidBody {
    if (this.params.type == 0 || this.params.boneIndex == -1) {
      return this;
    }

    this._updateBoneRotation();

    if (this.params.type == 1) {
      this._updateBonePosition();
    }

    this.bone.updateMatrixWorld(true);

    if (this.params.type == 2) {
      this._setPositionFromBone();
    }

    return this;
  }

  private function _init() {
    var generateShape = function(p:RigidBodyParam):Dynamic {
      switch (p.shapeType) {
        case 0:
          return new Ammo.btSphereShape(p.width);
        case 1:
          return new Ammo.btBoxShape(new Ammo.btVector3(p.width, p.height, p.depth));
        case 2:
          return new Ammo.btCapsuleShape(p.width, p.height);
        default:
          throw new Error("unknown shape type " + p.shapeType);
      }
    };

    var manager = this.manager;
    var params = this.params;
    var bones = this.mesh.skeleton.bones;
    var bone = (params.boneIndex == -1) ? new Bone() : bones[params.boneIndex];

    var shape = generateShape(params);
    var weight = (params.type == 0) ? 0 : params.weight;
    var localInertia = manager.allocVector3();
    localInertia.setValue(0, 0, 0);

    if (weight != 0) {
      shape.calculateLocalInertia(weight, localInertia);
    }

    var boneOffsetForm = manager.allocTransform();
    manager.setIdentity(boneOffsetForm);
    manager.setOriginFromArray3(boneOffsetForm, params.position);
    manager.setBasisFromArray3(boneOffsetForm, params.rotation);

    var vector = manager.allocThreeVector3();
    var boneForm = manager.allocTransform();
    manager.setIdentity(boneForm);
    manager.setOriginFromThreeVector3(boneForm, bone.getWorldPosition(vector));

    var form = manager.multiplyTransforms(boneForm, boneOffsetForm);
    var state = new Ammo.btDefaultMotionState(form);

    var info = new Ammo.btRigidBodyConstructionInfo(weight, state, shape, localInertia);
    info.set_m_friction(params.friction);
    info.set_m_restitution(params.restitution);

    var body = new Ammo.btRigidBody(info);

    if (params.type == 0) {
      body.setCollisionFlags(body.getCollisionFlags() | 2);

      /*
       * It'd be better to comment out this line though in general I should call this method
       * because I'm not sure why but physics will be more like MMD's
       * if I comment out.
       */
      body.setActivationState(4);
    }

    body.setDamping(params.positionDamping, params.rotationDamping);
    body.setSleepingThresholds(0, 0);

    this.world.addRigidBody(body, 1 << params.groupIndex, params.groupTarget);

    this.body = body;
    this.bone = bone;
    this.boneOffsetForm = boneOffsetForm;
    this.boneOffsetFormInverse = manager.inverseTransform(boneOffsetForm);

    manager.freeVector3(localInertia);
    manager.freeTransform(form);
    manager.freeTransform(boneForm);
    manager.freeThreeVector3(vector);
  }

  private function _getBoneTransform():Dynamic {
    var manager = this.manager;
    var p = manager.allocThreeVector3();
    var q = manager.allocThreeQuaternion();
    var s = manager.allocThreeVector3();

    this.bone.matrixWorld.decompose(p, q, s);

    var tr = manager.allocTransform();
    manager.setOriginFromThreeVector3(tr, p);
    manager.setBasisFromThreeQuaternion(tr, q);

    var form = manager.multiplyTransforms(tr, this.boneOffsetForm);

    manager.freeTransform(tr);
    manager.freeThreeVector3(s);
    manager.freeThreeQuaternion(q);
    manager.freeThreeVector3(p);

    return form;
  }

  private function _getWorldTransformForBone():Dynamic {
    var manager = this.manager;
    var tr = this.body.getCenterOfMassTransform();
    return manager.multiplyTransforms(tr, this.boneOffsetFormInverse);
  }

  private function _setTransformFromBone() {
    var manager = this.manager;
    var form = this._getBoneTransform();

    // TODO: check the most appropriate way to set
    //this.body.setWorldTransform(form);
    this.body.setCenterOfMassTransform(form);
    this.body.getMotionState().setWorldTransform(form);

    manager.freeTransform(form);
  }

  private function _setPositionFromBone() {
    var manager = this.manager;
    var form = this._getBoneTransform();

    var tr = manager.allocTransform();
    this.body.getMotionState().getWorldTransform(tr);
    manager.copyOrigin(tr, form);

    // TODO: check the most appropriate way to set
    //this.body.setWorldTransform(tr);
    this.body.setCenterOfMassTransform(tr);
    this.body.getMotionState().setWorldTransform(tr);

    manager.freeTransform(tr);
    manager.freeTransform(form);
  }

  private function _updateBoneRotation() {
    var manager = this.manager;

    var tr = this._getWorldTransformForBone();
    var q = manager.getBasis(tr);

    var thQ = manager.allocThreeQuaternion();
    var thQ2 = manager.allocThreeQuaternion();
    var thQ3 = manager.allocThreeQuaternion();

    thQ.set(q.x(), q.y(), q.z(), q.w());
    thQ2.setFromRotationMatrix(this.bone.matrixWorld);
    thQ2.conjugate();
    thQ2.multiply(thQ);

    //this.bone.quaternion.multiply(thQ2);

    thQ
    thQ3.setFromRotationMatrix(this.bone.matrix);

    // Renormalizing quaternion here because repeatedly transforming
    // quaternion continuously accumulates floating point error and
    // can end up being overflow. See #15335
    this.bone.quaternion.copy(thQ2.multiply(thQ3).normalize());

    manager.freeThreeQuaternion(thQ);
    manager.freeThreeQuaternion(thQ2);
    manager.freeThreeQuaternion(thQ3);

    manager.freeQuaternion(q);
    manager.freeTransform(tr);
  }

  private function _updateBonePosition() {
    var manager = this.manager;

    var tr = this._getWorldTransformForBone();

    var thV = manager.allocThreeVector3();

    var o = manager.getOrigin(tr);
    thV.set(o.x(), o.y(), o.z());

    if (this.bone.parent != null) {
      this.bone.parent.worldToLocal(thV);
    }

    this.bone.position.copy(thV);

    manager.freeThreeVector3(thV);

    manager.freeTransform(tr);
  }
}

//

class Constraint {
  /**
   * @param {THREE.SkinnedMesh} mesh
   * @param {Ammo.btDiscreteDynamicsWorld} world
   * @param {RigidBody} bodyA
   * @param {RigidBody} bodyB
   * @param {Object} params
   * @param {ResourceManager} manager
   */
  public var mesh:SkinnedMesh;
  public var world:Dynamic;
  public var bodyA:RigidBody;
  public var bodyB:RigidBody;
  public var params:ConstraintParam;
  public var manager:ResourceManager;
  public var constraint:Dynamic;

  public function new(mesh:SkinnedMesh, world:Dynamic, bodyA:RigidBody, bodyB:RigidBody, params:ConstraintParam, manager:ResourceManager) {
    this.mesh = mesh;
    this.world = world;
    this.bodyA = bodyA;
    this.bodyB = bodyB;
    this.params = params;
    this.manager = manager;

    this.constraint = null;

    this._init();
  }

  // private method

  private function _init() {
    var manager = this.manager;
    var params = this.params;
    var bodyA = this.bodyA;
    var bodyB = this.bodyB;

    var form = manager.allocTransform();
    manager.setIdentity(form);
    manager.setOriginFromArray3(form, params.position);
    manager.setBasisFromArray3(form, params.rotation);

    var formA = manager.allocTransform();
    var formB = manager.allocTransform();

    bodyA.body.getMotionState().getWorldTransform(formA);
    bodyB.body.getMotionState().getWorldTransform(formB);

    var formInverseA = manager.inverseTransform(formA);
    var formInverseB = manager.inverseTransform(formB);

    var formA2 = manager.multiplyTransforms(formInverseA, form);
    var formB2 = manager.multiplyTransforms(formInverseB, form);

    var constraint = new Ammo.btGeneric6DofSpringConstraint(bodyA.body, bodyB.body, formA2, formB2, true);

    var lll = manager.allocVector3();
    var lul = manager.allocVector3();
    var all = manager.allocVector3();
    var aul = manager.allocVector3();

    lll.setValue(params.translationLimitation1[0],
                 params.translationLimitation1[1],
                 params.translationLimitation1[2]);
    lul.setValue(params.translationLimitation2[0],
                 params.translationLimitation2[1],
                 params.translationLimitation2[2]);
    all.setValue(params.rotationLimitation1[0],
                 params.rotationLimitation1[1],
                 params.rotationLimitation1[2]);
    aul.setValue(params.rotationLimitation2[0],
                 params.rotationLimitation2[1],
                 params.rotationLimitation2[2]);

    constraint.setLinearLowerLimit(lll);
    constraint.setLinearUpperLimit(lul);
    constraint.setAngularLowerLimit(all);
    constraint.setAngularUpperLimit(aul);

    for (i in 0...3) {
      if (params.springPosition[i] != 0) {
        constraint.enableSpring(i, true);
        constraint.setStiffness(i, params.springPosition[i]);
      }
    }

    for (i in 0...3) {
      if (params.springRotation[i] != 0) {
        constraint.enableSpring(i + 3, true);
        constraint.setStiffness(i + 3, params.springRotation[i]);
      }
    }

    /*
     * Currently(10/31/2016) official ammo.js doesn't support
     * btGeneric6DofSpringConstraint.setParam method.
     * You need custom ammo.js (add the method into idl) if you wanna use.
     * By setting this parameter, physics will be more like MMD's
     */
    if (constraint.setParam != null) {
      for (i in 0...6) {
        constraint.setParam(2, 0.475, i);
      }
    }

    this.world.addConstraint(constraint, true);
    this.constraint = constraint;

    manager.freeTransform(form);
    manager.freeTransform(formA);
    manager.freeTransform(formB);
    manager.freeTransform(formInverseA);
    manager.freeTransform(formInverseB);
    manager.freeTransform(formA2);
    manager.freeTransform(formB2);
    manager.freeVector3(lll);
    manager.freeVector3(lul);
    manager.freeVector3(all);
    manager.freeVector3(aul);
  }
}

//

const _position = new Vector3();
const _quaternion = new Quaternion();
const _scale = new Vector3();
const _matrixWorldInv = new Matrix4();

class MMDPhysicsHelper extends Object3D {
  /**
   * Visualize Rigid bodies
   *
   * @param {THREE.SkinnedMesh} mesh
   * @param {Physics} physics
   */
  public var root:SkinnedMesh;
  public var physics:MMDPhysics;
  public var materials:Array<MeshBasicMaterial>;

  public function new(mesh:SkinnedMesh, physics:MMDPhysics) {
    super();

    this.root = mesh;
    this.physics = physics;

    this.matrix.copy(mesh.matrixWorld);
    this.matrixAutoUpdate = false;

    this.materials = [];
    this.materials.push(new MeshBasicMaterial({
      color: new Color(0xff8888),
      wireframe: true,
      depthTest: false,
      depthWrite: false,
      opacity: 0.25,
      transparent: true
    }));

    this.materials.push(new MeshBasicMaterial({
      color: new Color(0x88ff88),
      wireframe: true,
      depthTest: false,
      depthWrite: false,
      opacity: 0.25,
      transparent: true
    }));

    this.materials.push(new MeshBasicMaterial({
      color: new Color(0x8888ff),
      wireframe: true,
      depthTest: false,
      depthWrite: false,
      opacity: 0.25,
      transparent: true
    }));

    this._init();
  }

  /**
   * Frees the GPU-related resources allocated by this instance. Call this method whenever this instance is no longer used in your app.
   */
  public function dispose() {
    var materials = this.materials;
    var children = this.children;

    for (i in 0...materials.length) {
      materials[i].dispose();
    }

    for (i in 0...children.length) {
      var child = children[i];

      if (child.isMesh) child.geometry.dispose();
    }
  }

  /**
   * Updates Rigid Bodies visualization.
   */
  public function updateMatrixWorld(force:Bool) {
    var mesh = this.root;

    if (this.visible) {
      var bodies = this.physics.bodies;

      _matrixWorldInv
        .copy(mesh.matrixWorld)
        .decompose(_position, _quaternion, _scale)
        .compose(_position, _quaternion, _scale.set(1, 1, 1))
        .invert();

      for (i in 0...bodies.length) {
        var body = bodies[i].body;
        var child = this.children[i];

        var tr = body.getCenterOfMassTransform();
        var origin = tr.getOrigin();
        var rotation = tr.getRotation();

        child.position
          .set(origin.x(), origin.y(), origin.z())
          .applyMatrix4(_matrixWorldInv);

        child.quaternion
          .setFromRotationMatrix(_matrixWorldInv)
          .multiply(
            _quaternion.set(rotation.x(), rotation.y(), rotation.z(), rotation.w())
          );
      }
    }

    this.matrix
      .copy(mesh.matrixWorld)
      .decompose(_position, _quaternion, _scale)
      .compose(_position, _quaternion, _scale.set(1, 1, 1));

    super.updateMatrixWorld(force);
  }

  // private method

  private function _init() {
    var bodies = this.physics.bodies;

    var createGeometry = function(param:RigidBodyParam):Dynamic {
      switch (param.shapeType) {
        case 0:
          return new SphereGeometry(param.width, 16, 8);
        case 1:
          return new BoxGeometry(param.width * 2, param.height * 2, param.depth * 2, 8, 8, 8);
        case 2:
          return new CapsuleGeometry(param.width, param.height, 8, 16);
        default:
          return null;
      }
    };

    for (i in 0...bodies.length) {
      var param = bodies[i].params;
      this.add(new Mesh(createGeometry(param), this.materials[param.type]));
    }
  }
}

export class MMDPhysics {
  public static function create(mesh:SkinnedMesh, rigidBodyParams:Array<RigidBodyParam>, constraintParams:Array<ConstraintParam> = [], params:Dynamic = null):MMDPhysics {
    return new MMDPhysics(mesh, rigidBodyParams, constraintParams, params);
  }
}