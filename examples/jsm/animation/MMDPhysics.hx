import three.math.Box3;
import three.math.Euler;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Sphere;
import three.math.Vector3;
import three.core.Object3D;
import three.core.Mesh;
import three.materials.MeshBasicMaterial;
import three.geometries.BoxGeometry;
import three.geometries.CapsuleGeometry;
import three.geometries.SphereGeometry;

class MMDPhysics {

	public var manager:ResourceManager;
	public var mesh:SkinnedMesh;
	public var unitStep:Float;
	public var maxStepNum:Int;
	public var gravity:Vector3;
	public var world:btDiscreteDynamicsWorld;
	public var bodies:Array<RigidBody>;
	public var constraints:Array<Constraint>;

	public function new(mesh:SkinnedMesh, rigidBodyParams:Array<Dynamic>, constraintParams:Array<Dynamic>=null, params:Dynamic=null) {
		if (Ammo === undefined) {
			throw new Error("THREE.MMDPhysics: Import ammo.js https://github.com/kripken/ammo.js");
		}
		this.manager = new ResourceManager();
		this.mesh = mesh;
		this.unitStep = (params.unitStep !== undefined) ? params.unitStep : 1 / 65;
		this.maxStepNum = (params.maxStepNum !== undefined) ? params.maxStepNum : 3;
		this.gravity = new Vector3(0, -9.8 * 10, 0);
		if (params.gravity !== undefined) this.gravity.copy(params.gravity);
		this.world = (params.world !== undefined) ? params.world : null;
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
		if (scale.x !== 1 || scale.y !== 1 || scale.z !== 1) {
			isNonDefaultScale = true;
		}
		var parent = mesh.parent;
		if (isNonDefaultScale) {
			if (parent !== null) mesh.parent = null;
			scale.copy(this.mesh.scale);
			mesh.scale.set(1, 1, 1);
			mesh.updateMatrixWorld(true);
		}
		this._updateRigidBodies();
		this._stepSimulation(delta);
		this._updateBones();
		if (isNonDefaultScale) {
			if (parent !== null) mesh.parent = parent;
			mesh.scale.copy(scale);
		}
		manager.freeThreeVector3(scale);
		manager.freeThreeQuaternion(quaternion);
		manager.freeThreeVector3(position);
		return this;
	}

	public function reset():MMDPhysics {
		for (i in this.bodies) {
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

	private function _init(mesh:SkinnedMesh, rigidBodyParams:Array<Dynamic>, constraintParams:Array<Dynamic>) {
		var manager = this.manager;
		var parent = mesh.parent;
		if (parent !== null) mesh.parent = null;
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
		if (this.world === null) {
			this.world = this._createWorld();
			this.setGravity(this.gravity);
		}
		this._initRigidBodies(rigidBodyParams);
		this._initConstraints(constraintParams);
		if (parent !== null) mesh.parent = parent;
		mesh.position.copy(currentPosition);
		mesh.quaternion.copy(currentQuaternion);
		mesh.scale.copy(currentScale);
		mesh.updateMatrixWorld(true);
		this.reset();
		manager.freeThreeVector3(currentPosition);
		manager.freeThreeQuaternion(currentQuaternion);
		manager.freeThreeVector3(currentScale);
	}

	private function _createWorld():btDiscreteDynamicsWorld {
		var config = new Ammo.btDefaultCollisionConfiguration();
		var dispatcher = new Ammo.btCollisionDispatcher(config);
		var cache = new Ammo.btDbvtBroadphase();
		var solver = new Ammo.btSequentialImpulseConstraintSolver();
		var world = new Ammo.btDiscreteDynamicsWorld(dispatcher, cache, solver, config);
		return world;
	}

	private function _initRigidBodies(rigidBodies:Array<Dynamic>) {
		for (i in rigidBodies) {
			this.bodies.push(new RigidBody(this.mesh, this.world, rigidBodies[i], this.manager));
		}
	}

	private function _initConstraints(constraints:Array<Dynamic>) {
		for (i in constraints) {
			var params = constraints[i];
			var bodyA = this.bodies[params.rigidBodyIndex1];
			var bodyB = this.bodies[params.rigidBodyIndex2];
			this.constraints.push(new Constraint(this.mesh, this.world, bodyA, bodyB, params, this.manager));
		}
	}

	private function _stepSimulation(delta:Float) {
		var unitStep = this.unitStep;
		var stepTime = delta;
		var maxStepNum = ((delta / unitStep) | 0) + 1;
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
		for (i in this.bodies) {
			this.bodies[i].updateFromBone();
		}
	}

	private function _updateBones() {
		for (i in this.bodies) {
			this.bodies[i].updateBone();
		}
	}

}

class ResourceManager {

	public var threeVector3s:Array<Vector3>;
	public var threeMatrix4s:Array<Matrix4>;
	public var threeQuaternions:Array<Quaternion>;
	public var threeEulers:Array<Euler>;
	public var transforms:Array<btTransform>;
	public var quaternions:Array<btQuaternion>;
	public var vector3s:Array<btVector3>;

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

	public function allocTransform():btTransform {
		return (this.transforms.length > 0) ? this.transforms.pop() : new btTransform();
	}

	public function freeTransform(t:btTransform) {
		this.transforms.push(t);
	}

	public function allocQuaternion():btQuaternion {
		return (this.quaternions.length > 0) ? this.quaternions.pop() : new btQuaternion();
	}

	public function freeQuaternion(q:btQuaternion) {
		this.quaternions.push(q);
	}

	public function allocVector3():btVector3 {
		return (this.vector3s.length > 0) ? this.vector3s.pop() : new btVector3();
	}

	public function freeVector3(v:btVector3) {
		this.vector3s.push(v);
	}

	public function setIdentity(t:btTransform) {
		t.setIdentity();
	}

	public function getBasis(t:btTransform):Quaternion {
		var q = this.allocQuaternion();
		t.getBasis().getRotation(q);
		return q;
	}

	public function getBasisAsMatrix3(t:btTransform):Matrix4 {
		var q = this.getBasis(t);
		var m = q.toMatrix3();
		this.freeQuaternion(q);
		return m;
	}

	public function getOrigin(t:btTransform):Vector3 {
		return new Vector3(t.getOrigin().x(), t.getOrigin().y(), t.getOrigin().z());
	}

	public function setOrigin(t:btTransform, v:Vector3) {
		t.getOrigin().setValue(v.x, v.y, v.z);
	}

	public function copyOrigin(t1:btTransform, t2:btTransform) {
		var o = t2.getOrigin();
		this.setOrigin(t1, o);
	}

	public function setBasis(t:btTransform, q:Quaternion) {
		t.setRotation(q);
	}

	public function setBasisFromMatrix3(t:btTransform, m:Matrix4) {
		var q = m.toQuaternion();
		this.setBasis(t, q);
		this.freeQuaternion(q);
	}

	public function setOriginFromArray3(t:btTransform, a:Array<Float>) {
		t.getOrigin().setValue(a[0], a[1], a[2]);
	}

	public function setOriginFromThreeVector3(t:btTransform, v:Vector3) {
		t.getOrigin().setValue(v.x, v.y, v.z);
	}

	public function setBasisFromArray3(t:btTransform, a:Array<Float>) {
		var thQ = this.allocThreeQuaternion();
		var thE = this.allocThreeEuler();
		thE.set(a[0], a[1], a[2]);
		this.setBasisFromThreeQuaternion(t, thQ.setFromEuler(thE));
		this.freeThreeEuler(thE);
		this.freeThreeQuaternion(thQ);
	}

	public function setBasisFromThreeQuaternion(t:btTransform, a:Quaternion) {
		var q = this.allocQuaternion();
		q.set(a.x, a.y, a.z, a.w);
		this.setBasis(t, q);
		this.freeQuaternion(q);
	}

	public function multiplyTransforms(t1:btTransform, t2:btTransform):btTransform {
		var t = this.allocTransform();
		this.setIdentity(t);
		var m1 = this.getBasisAsMatrix3(t1);
		var m2 = this.getBasisAsMatrix3(t2);
		var o1 = this.getOrigin(t1);
		var o2 = this.getOrigin(t2);
		var v1 = m1.multiplyVector3(o2);
		var v2 = v1.add(o1);
		this.setOrigin(t, v2);
		var m3 = m1.multiply(m2);
		this.setBasisFromMatrix3(t, m3);
		this.freeVector3(v1);
		this.freeVector3(v2);
		return t;
	}

	public function inverseTransform(t:btTransform):btTransform {
		var t2 = this.allocTransform();
		var m1 = this.getBasisAsMatrix3(t);
		var o = this.getOrigin(t);
		var m2 = this.transposeMatrix3(m1);
		var v1 = this.negativeVector3(o);
		var v2 = m2.multiplyVector3(v1);
		this.setOrigin(t2, v2);
		this.setBasisFromMatrix3(t2, m2);
		return t2;
	}

	public function multiplyMatrices3(m1:Matrix3, m2:Matrix3):Array<Float> {
		var m3 = [];
		var v10 = m1.elements[0 * 3 + 0];
		var v11 = m1.elements[0 * 3 + 1];
		var v12 = m1.elements[0 * 3 + 2];
		var v20 = m2.elements[0];
		var v21 = m2.elements[1];
		var v22 = m2.elements[2];
		m3[0] = v10 * v20 + v11 * v21 + v12 * v22;
		m3[1] = v10 * v21 + v11 * v22 + v12 * v23;
		m3[2] = v10 * v22 + v11 * v23 + v12 * v24;
		m3[3] = v13 * v20 + v14 * v21 + v15 * v22;
		m3[4] = v13 * v21 + v14 * v22 + v15 * v23;
		m3[5] = v13 * v22 + v14 * v23 + v15 * v24;
		m3[6] = v16 * v20 + v17 * v21 + v18 * v22;
		m3[7] = v16 * v21 + v17 * v22 + v18 * v23;
		m3[8] = v16 * v22 + v17 * v23 + v18 * v24;
		return m3;
	}

	public function addVector3(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
	}

	public function dotVectors3(v1:Vector3, v2:Vector3):Float {
		return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
	}

	public function rowOfMatrix3(m:Matrix3, i:Int):Vector3 {
		return new Vector3(m.elements[i * 3 + 0], m.elements[i * 3 + 1], m.elements[i * 3 + 2]);
	}

	public function columnOfMatrix3(m:Matrix3, i:Int):Vector3 {
		return new Vector3(m.elements[i], m.elements[i + 3], m.elements[i + 6]);
	}

	public function negativeVector3(v:Vector3):Vector3 {
		return new Vector3(-v.x, -v.y, -v.z);
	}

	public function multiplyMatrix3ByVector3(m:Matrix3, v:Vector3):Vector3 {
		var v4 = new Vector3();
		v4.set(this.dotVectors3(m.elements[0], v), this.dotVectors3(m.elements[3], v), this.dotVectors3(m.elements[6], v));
		return v4;
	}

	public function transposeMatrix3(m:Matrix3):Array<Float> {
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

	public function quaternionToMatrix3(q:Quaternion):Matrix3 {
		var m = [];
		var x = q.x;
		var y = q.y;
		var z = q.z;
		var w = q.w;
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

	public function matrix3ToQuaternion(m:Matrix3):Quaternion {
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
		var m3 = new Matrix3(m2);
		var tr = m3.trace();
		var q = new Quaternion();
		if (tr > 0) {
			var s = Math.sqrt(tr + 1) * 2;
			q.w = s / 4;
			q.x = (m3.elements[7] - m3.elements[5]) / s;
			q.y = (m3.elements[2] - m3.elements[6]) / s;
			q.z = (m3.elements[3] - m3.elements[1]) / s;
		} else {
			if (m3.elements[0] > m3.elements[4] && m3.elements[0] > m3.elements[8]) {
				var s = Math.sqrt(1 + m3.elements[0] - m3.elements[4] - m3.elements[8]) * 2;
				q.x = s / 4;
				q.w = (m3.elements[7] - m3.elements[5]) / s;
				q.y = (m3.elements[1] + m3.elements[3]) / s;
				q.z = (m3.elements[2] + m3.elements[6]) / s;
			} else if (m3.elements[4] > m3.elements[8]) {
				var s = Math.sqrt(1 + m3.elements[4] - m3.elements[0] - m3.elements[8]) * 2;
				q.y = s / 4;
				q.w = (m3.elements[2] - m3.elements[6]) / s;
				q.x = (m3.elements[1] + m3.elements[3]) / s;
				q.z = (m3.elements[5] + m3.elements[7]) / s;
			} else {
				var s = Math.sqrt(1 + m3.elements[8] - m3.elements[0] - m3.elements[4]) * 2;
				q.z = s / 4;
				q.w = (m3.elements[3] - m3.elements[1]) / s;
				q.x = (m3.elements[2] + m3.elements[6]) / s;
				q.y = (m3.elements[5] + m3.elements[7]) / s;
			}
		}
		return q;
	}

}

//... (other classes)