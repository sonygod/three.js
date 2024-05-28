import js.three.*;

class MMDPhysics {
	public var manager:ResourceManager;
	public var mesh:SkinnedMesh;
	public var unitStep:Float;
	public var maxStepNum:Int;
	public var gravity:Vector3;
	public var world:Ammo.btDiscreteDynamicsWorld;
	public var bodies:Array<RigidBody>;
	public var constraints:Array<Constraint>;

	public function new(mesh:SkinnedMesh, rigidBodyParams:Array<Dynamic>, ?constraintParams:Array<Dynamic>, ?params:Dynamic) {
		if (js.Lib.typeof(Ammo) == js.Lib.UNDEFINED) {
			throw "THREE.MMDPhysics: Import ammo.js https://github.com/kripken/ammo.js";
		}

		manager = new ResourceManager();
		this.mesh = mesh;
		unitStep = (params != null && params.unitStep != null) ? params.unitStep : 1 / 65;
		maxStepNum = (params != null && params.maxStepNum != null) ? params.maxStepNum : 3;
		gravity = new Vector3(0, -9.8 * 10, 0);
		if (params != null && params.gravity != null)
			gravity.copy(params.gravity);
		world = (params != null && params.world != null) ? params.world : null;
		bodies = [];
		constraints = [];
		_init(mesh, rigidBodyParams, constraintParams);
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
		var parent:Object3D;
		if (isNonDefaultScale) {
			parent = mesh.parent;
			if (parent != null)
				mesh.parent = null;
			scale.copy(mesh.scale);
			mesh.scale.set(1, 1, 1);
			mesh.updateMatrixWorld(true);
		}
		_updateRigidBodies();
		_stepSimulation(delta);
		_updateBones();
		if (isNonDefaultScale) {
			if (parent != null)
				mesh.parent = parent;
			mesh.scale.copy(scale);
		}
		manager.freeThreeVector3(scale);
		manager.freeThreeQuaternion(quaternion);
		manager.freeThreeVector3(position);
		return this;
	}

	public function reset():MMDPhysics {
		for (i in 0...bodies.length) {
			bodies[i].reset();
		}
		return this;
	}

	public function warmup(cycles:Int):MMDPhysics {
		for (i in 0...cycles) {
			update(1 / 60);
		}
		return this;
	}

	public function setGravity(gravity:Vector3):MMDPhysics {
		world.setGravity(new Ammo.btVector3(gravity.x, gravity.y, gravity.z));
		this.gravity.copy(gravity);
		return this;
	}

	public function createHelper():MMDPhysicsHelper {
		return new MMDPhysicsHelper(mesh, this);
	}

	private function _init(mesh:SkinnedMesh, rigidBodyParams:Array<Dynamic>, constraintParams:Array<Dynamic>) {
		var manager = this.manager;
		var parent = mesh.parent;
		if (parent != null)
			mesh.parent = null;
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
		if (world == null) {
			world = _createWorld();
			setGravity(gravity);
		}
		_initRigidBodies(rigidBodyParams);
		_initConstraints(constraintParams);
		if (parent != null)
			mesh.parent = parent;
		mesh.position.copy(currentPosition);
		mesh.quaternion.copy(currentQuaternion);
		mesh.scale.copy(currentScale);
		mesh.updateMatrixWorld(true);
		reset();
		manager.freeThreeVector3(currentPosition);
		manager.freeThreeQuaternion(currentQuaternion);
		manager.freeThreeVector3(currentScale);
	}

	private function _createWorld():Ammo.btDiscreteDynamicsWorld {
		var config = new Ammo.btDefaultCollisionConfiguration();
		var dispatcher = new Ammo.btCollisionDispatcher(config);
		var cache = new Ammo.btDbvtBroadphase();
		var solver = new Ammo.btSequentialImpulseConstraintSolver();
		var world = new Ammo.btDiscreteDynamicsWorld(dispatcher, cache, solver, config);
		return world;
	}

	private function _initRigidBodies(rigidBodies:Array<Dynamic>) {
		for (i in 0...rigidBodies.length) {
			bodies.push(new RigidBody(mesh, world, rigidBodies[i], manager));
		}
	}

	private function _initConstraints(constraints:Array<Dynamic>) {
		for (i in 0...constraints.length) {
			var params = constraints[i];
			var bodyA = bodies[params.rigidBodyIndex1];
			var bodyB = bodies[params.rigidBodyIndex2];
			this.constraints.push(new Constraint(mesh, world, bodyA, bodyB, params, manager));
		}
	}

	private function _stepSimulation(delta:Float) {
		var unitStep = this.unitStep;
		var stepTime = delta;
		var maxStepNum = (delta / unitStep) | 0 + 1;
		if (stepTime < unitStep) {
			stepTime = unitStep;
			maxStepNum = 1;
		}
		if (maxStepNum > this.maxStepNum) {
			maxStepNum = this.maxStepNum;
		}
		world.stepSimulation(stepTime, maxStepNum, unitStep);
	}

	private function _updateRigidBodies() {
		for (i in 0...bodies.length) {
			bodies[i].updateFromBone();
		}
	}

	private function _updateBones() {
		for (i in 0...bodies.length) {
			bodies[i].updateBone();
		}
	}
}

class ResourceManager {
	public var threeVector3s:Array<Vector3>;
	public var threeMatrix4s:Array<Matrix4>;
	public var threeQuaternions:Array<Quaternion>;
	public var threeEulers:Array<Euler>;
	public var transforms:Array<Ammo.btTransform>;
	public var quaternions:Array<Ammo.btQuaternion>;
	public var vector3s:Array<Ammo.btVector3>;

	public function new() {
		threeVector3s = [];
		threeMatrix4s = [];
		threeQuaternions = [];
		threeEulers = [];
		transforms = [];
		quaternions = [];
		vector3s = [];
	}

	public function allocThreeVector3():Vector3 {
		return (threeVector3s.length > 0) ? threeVector3s.pop() : new Vector3();
	}

	public function freeThreeVector3(v:Vector3) {
		threeVector3s.push(v);
	}

	public function allocThreeMatrix4():Matrix4 {
		return (threeMatrix4s.length > 0) ? threeMatrix4s.pop() : new Matrix4();
	}

	public function freeThreeMatrix4(m:Matrix4) {
		threeMatrix4s.push(m);
	}

	public function allocThreeQuaternion():Quaternion {
		return (threeQuaternions.length > 0) ? threeQuaternions.pop() : new Quaternion();
	}

	public function freeThreeQuaternion(q:Quaternion) {
		threeQuaternions.push(q);
	}

	public function allocThreeEuler():Euler {
		return (threeEulers.length > 0) ? threeEulers.pop() : new Euler();
	}

	public function freeThreeEuler(e:Euler) {
		threeEulers.push(e);
	}

	public function allocTransform():Ammo.btTransform {
		return (transforms.length > 0) ? transforms.pop() : new Ammo.btTransform();
	}

	public function freeTransform(t:Ammo.btTransform) {
		transforms.push(t);
	}

	public function allocQuaternion():Ammo.btQuaternion {
		return (quaternions.length > 0) ? quaternions.pop() : new Ammo.btQuaternion();
	}

	public function freeQuaternion(q:Ammo.btQuaternion) {
		quaternions.push(q);
	}

	public function allocVector3():Ammo.btVector3 {
		return (vector3s.length > 0) ? vector3s.pop() : new Ammo.btVector3();
	}

	public function freeVector3(v:Ammo.btVector3) {
		vector3s.push(v);
	}

	public function setIdentity(t:Ammo.btTransform) {
		t.setIdentity();
	}

	public function getBasis(t:Ammo.btTransform):Ammo.btQuaternion {
		var q = allocQuaternion();
		t.getBasis().getRotation(q);
		return q;
	}

	public function getBasisAsMatrix3(t:Ammo.btTransform):Array<Float> {
		var q = getBasis(t);
		var m = quaternionToMatrix3(q);
		freeQuaternion(q);
		return m;
	}

	public function getOrigin(t:Ammo.btTransform):Ammo.btVector3 {
		return t.getOrigin();
	}

	public function setOrigin(t:Ammo.btTransform, v:Ammo.btVector3) {
		t.getOrigin().setValue(v.x(), v.y(), v.z());
	}

	public function copyOrigin(t1:Ammo.btTransform, t2:Ammo.btTransform) {
		var o = t2.getOrigin();
		setOrigin(t1, o);
	}

	public function setBasis(t:Ammo.btTransform, q:Ammo.btQuaternion) {
		t.setRotation(q);
	}

	public function setBasisFromMatrix3(t:Ammo.btTransform, m:Array<Float>) {
		var q = matrix3ToQuaternion(m);
		setBasis(t, q);
		freeQuaternion(q);
	}

	public function setOriginFromArray3(t:Ammo.btTransform, a:Array<Float>) {
		t.getOrigin().setValue(a[0], a[1], a[2]);
	}

	public function setOriginFromThreeVector3(t:Ammo.btTransform, v:Vector3) {
		t.getOrigin().setValue(v.x, v.y, v.z);
	}

	public function setBasisFromArray3(t:Ammo.btTransform, a:Array<Float>) {
		var thQ = allocThreeQuaternion();
		var thE = allocThreeEuler();
		thE.set(a[0], a[1], a[2]);
		setBasisFromThreeQuaternion(t, thQ.setFromEuler(thE));
		freeThreeEuler(thE);
		freeThreeQuaternion(thQ);
	}

	public function setBasisFromThreeQuaternion(t:Ammo.btTransform, a:Quaternion) {
		var q = allocQuaternion();
		q.setX(a.x);
		q.setY(a.y);
		q.setZ(a.z);
		q.setW(a.w);
		setBasis(t, q);
		freeQuaternion(q);
	}

	public function multiplyTransforms(t1:Ammo.btTransform, t2:Ammo.btTransform):Ammo.btTransform {
		var t = allocTransform();
		setIdentity(t);
		var m1 = getBasisAsMatrix3(t1);
		var m2 = getBasisAsMatrix3(t2);
		var o1 = getOrigin(t1);
		var o2 = getOrigin(t2);
		var v1 = multiplyMatrix3ByVector3(m1, o2);
		var v2 = addVector3(v1, o1);
		setOrigin(t, v2);
		var m3 = multiplyMatrices3(m1, m2);
		setBasisFromMatrix3(t, m3);
		freeVector3(v1);
		freeVector3(v2);
		return t;
	}

	public function inverseTransform(t:Ammo.btTransform):Ammo.btTransform {
		var t2 = allocTransform();
		var m1 = getBasisAsMatrix3(t);
		var o = getOrigin(t);
		var m2 = transposeMatrix3(m1);
		var v1 = negativeVector3(o);
		var v2 = multiplyMatrix3ByVector3(m2, v1);
		setOrigin(t2, v2);
		setBasisFromMatrix3(t2, m2);
		freeVector3(v1);
		freeVector3(v2);
		return t2;
	}

	public function multiplyMatrices3(m1:Array<Float>, m2:Array<Float>):Array<Float> {
		var m3 = [];
		var v10 = rowOfMatrix3(m1, 0);
		var v11 = rowOfMatrix3(m1, 1);
		var v12 = rowOfMatrix3(m1, 2);
		var v20 = columnOfMatrix3(m2, 0);
		var v21 = columnOfMatrix3(m2, 1);
		var v22 = columnOfMatrix3(m2, 2);
		m3[0] = dotVectors3(v10, v20);
		m3[1] = dotVectors3(v10, v21);
		m3[2] = dotVectors3(v10, v22);
		m3[3] = dotVectors3(v11, v20);
		m3[4] = dotVectors3(v11, v21);
		m3[5] = dotVectors3(v11, v22);
		m3[6] = dotVectors3(v12, v20);
		m3[7] = dotVectors3(v12, v21);
		m3[8] = dotVectors3(v12, v22);
		freeVector3(v10);
		freeVector3(v11);
		freeVector3(v12);
		freeVector3(v20);
		freeVector3(v21);
		freeVector3(v22);
		return m3;
	}

	public function addVector3(v1:Ammo.btVector3, v2:Ammo.btVector3):Ammo.btVector3 {
		var v = allocVector3();
		v.setValue(v1.x() + v2.x(), v1.y() + v2.y(), v1.z() + v2.z());
		return v;
	}

	public function dotVectors3(v1:Ammo.btVector3, v2:Ammo.btVector3):Float {
		return v1.x() * v2.x() + v1.y() * v2.y() + v1.z() * v2.z();
	}

	public function rowOfMatrix3(m:Array<Float>, i:Int):Ammo.btVector3 {
		var v = allocVector3();
		v.setValue(m[i * 3 + 0], m[i * 3 + 1], m[i * 3 + 2]);
		return v;
	}

	public function columnOfMatrix3(m:Array<Float>, i:Int):Ammo.btVector3 {
		var v = allocVector3();
		v.setValue(m[i + 0], m[i + 3], m[i + 6]);
		return v;
	}

	public function negativeVector3(v:Ammo.btVector3):Ammo.btVector3 {
		var v2 = allocVector3();
		v2.setValue(-v.x(), -v.y(), -v.z());
		return v2;
	}

	public function multiplyMatrix3ByVector3(m:Array<Float>, v:Ammo.btVector3):Ammo.btVector3 {
		var v4 = allocVector3();
		var v0 = rowOfMatrix3(m, 0);
		var v1 = rowOfMatrix3(m, 1);
		var v2 = rowOfMatrix3(m, 2);
		var x = dotVectors3(v0, v);
		var y = dotVectors3(v1, v);
		var z = dotVectors3(v2, v);
		v4.setValue(x, y, z);
		freeVector3(v0);
		freeVector3(v1);
		freeVector3(v2);
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

	public function quaternionToMatrix3(q:Ammo.btQuaternion):Array<Float> {
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

	public function matrix3ToQuaternion(m:Array<Float>):Ammo.btQuaternion {
		var t = m[0] + m[4] + m[8];
		var s:Float, x:Float, y:Float, z:Float, w:Float;
		if (t > 0) {
			s = Math.sqrt(t + 1.0) * 2;
			w = 0.25 * s;
			x = (m[7] - m[5]) / s;
			y = (m[2] - m[6]) / s;
			z = (m[3] - m[1]) / s;
		} else if (m[0] > m[4] && m[0] > m[8]) {
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
		var q = allocQuaternion();
		q.setX(x);
		q.setY(y);
		q.setZ(z);
		q.setW(w);
		return q;
	}
}

class RigidBody {
	public var mesh:SkinnedMesh;
	public var world:Ammo.btDiscreteDynamicsWorld;
	public var params:Dynamic;
	public var manager:ResourceManager;
	public var body:Ammo.btRigidBody;
	public var bone:Bone;
	public var boneOffsetForm:Ammo.btTransform;
	public var boneOffsetFormInverse:Ammo.btTransform;

	public function new(mesh:SkinnedMesh, world:Ammo.btDiscreteDynamicsWorld, params:Dynamic, manager:ResourceManager) {
		this.mesh = mesh;
		this.world = world;
		this.params = params;
		this.manager = manager;
		_init();
	}

	public function reset():RigidBody {
		_setTransformFromBone();
		return this;
	}

	public function updateFromBone():RigidBody {
		if (params.boneIndex != -1 && params.type == 0) {
			_setTransformFromBone();
		}
		return this;
	}

	public function updateBone():RigidBody {
		if (params.type == 0 || params.boneIndex == -1) {
			return this;
		}
		_updateBoneRotation();
		if (params.type == 1) {
			_updateBonePosition();
		}
		bone.updateMatrixWorld(true);
		if (params.type == 2) {
			_setPositionFromBone();
		}
		return this;
	}

	private function _init() {
		function generateShape(p:Dynamic):Ammo.btCollisionShape {
			switch (p.shapeType) {
				case 0:
					return new Ammo.btSphereShape(p.width);
				case 1:
					return new Ammo.btBoxShape(new Ammo.btVector3(p.width, p.height, p.depth));
				case 2:
					return new Ammo.btCapsuleShape(p.width, p.height);
				default:
					throw "unknown shape type " + Std.string(p.shapeType);
			}
		}
		var manager = this.manager;
		var params = this.params;
		var bones = mesh.skeleton.bones;
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
		body = new Ammo.btRigidBody(info);
		if (params.type == 0) {
			body.setCollisionFlags(body.getCollisionFlags() | 2);
			body.setActivationState(4);
		}
		body.setDamping(params.positionDamping, params.rotationDamping);
		body.setSleepingThresholds(0, 0);
		world.addRigidBody(body, 1 << params.groupIndex, params.groupTarget);
		this.body = body;
		this.bone = bone;
		this.boneOffsetForm = boneOffsetForm;
		this.boneOffsetFormInverse = manager.inverseTransform(boneOffsetForm);
		manager.freeVector3(localInertia);
		manager.freeTransform(form);
		manager.freeTransform(boneForm);
		manager.freeThreeVector3(vector);
	}

	private function _getBoneTransform():Ammo.btTransform {
		var manager = this.manager;
		var p = manager.allocThreeVector3();
		var q = manager.allocThreeQuaternion();
		var s = manager.allocThreeVector3();
		bone.matrixWorld.decompose(p, q, s);
		var tr = manager.allocTransform();
		manager.setOriginFromThreeVector3(tr, p);
		manager.setBasisFromThreeQuaternion(tr, q);
		var form = manager.multiplyTransforms(tr, boneOffsetForm);
		manager.freeTransform(tr);
		manager.freeThreeVector3(s);
		manager.freeThreeQuaternion(q);
		manager.freeThreeVector3(p);
		return form;
	}

	private function _getWorldTransformForBone():Ammo.btTransform {
		var manager = this.manager;
		var tr = body.getCenterOfMassTransform();
		return manager.multiplyTransforms(tr, boneOffsetFormInverse);
	}

	private function _setTransformFromBone() {
		var manager = this.manager;
		var form = _getBoneTransform();
		body.setCenterOfMassTransform(form);
		body.getMotionState().setWorldTransform(form);
		manager.freeTransform(form);
	}

	private function _setPositionFromBone() {
		var manager = this.manager;
		var form = _getBoneTransform();
		var tr = manager.allocTransform();
		body.getMotionState().getWorldTransform(tr);
		manager.copyOrigin(tr, form);
		body.setCenterOfMassTransform(tr);
		body.getMotionState().setWorldTransform(tr);
		manager.freeTransform(tr);
		manager.freeTransform(form);
	}

	private function _updateBoneRotation() {
		var manager = this.manager;
		var tr = _getWorldTransformForBone();
		var q = manager.getBasis(tr);
		var thQ = manager.allocThreeQuaternion();
		var thQ2 = manager.allocThreeQuaternion();
		var thQ3 = manager.allocThreeQuaternion();
		thQ.set(q.x(), q.y(), q.z(), q.w());
		thQ2.setFromRotationMatrix(bone.matrixWorld);
		thQ2.conjugate();
		thQ2.multiply(thQ);
		thQ3.setFromRotationMatrix(bone.matrix);
		bone.quaternion.copy(thQ2.multiply(thQ3).normalize());
		manager.freeThreeQuaternion(thQ);
		manager.freeThreeQuaternion(thQ2);
		manager.freeThreeQuaternion(thQ3);
		manager.freeQuaternion(q);
		manager.freeTransform(tr);
	}

	private function _updateBonePosition() {
		var manager = this.manager;
		var tr = _getWorldTransformForBone();
		var thV = manager.allocThreeVector3();
		var o = manager.getOrigin(tr);
		thV.set(o.x(), o.y(), o.z());
		if (bone.parent != null) {
			bone.parent.worldToLocal(thV);
		}
		bone.position.copy(thV);
		manager.freeThreeVector3(thV);
		manager.freeTransform(tr);
	}
}

class Constraint {
	public var mesh:SkinnedMesh;
	public var world:Ammo.btDiscreteDynamicsWorld;
	public var bodyA:RigidBody;
	public var bodyB:RigidBody;
	public var params:Dynamic;
	public var manager:ResourceManager;
	public var constraint:Ammo.btGeneric6DofSpringConstraint;

	public function new(mesh:SkinnedMesh, world:Ammo.btDiscreteDynamicsWorld, bodyA:RigidBody, bodyB:RigidBody, params:Dynamic, manager:ResourceManager) {
		this.mesh = mesh;
		this.world = world;
		this.bodyA = bodyA;
		this.bodyB = bodyB;
		this.params = params;
		this.manager = manager;
		_init();
	}

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
		constraint = new Ammo.btGeneric6DofSpringConstraint(bodyA.body, bodyB.body, formA2, formB2, true);
		var lll = manager.allocVector3();
		var lul = manager.allocVector3();
		var all = manager.allocVector3();
		var aul = manager.allocVector3();
		lll.setValue(params.translationLimitation1[0], params.translationLimitation1[1], params.translationLimitation1[2]);
		lul.setValue(params.translationLimitation2[0], params.translationLimitation2[1], params.translationLimitation2[2]);
		all.setValue(params.rotationLimitation1[0], params.rotationLimitation1[1], params.rotationLimitation1[2]);
		aul.setValue(params.rotationLimitation2[0], params.rotationLimitation2[1], params.rotationLimitation2[2]);
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
		if (constraint.setParam != null) {
			for (i in 0...6) {
				constraint.setParam(2, 0.475, i);
			}
		}
		world.addConstraint(constraint, true);
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

class MMDPhysicsHelper extends Object3D {
	public var root:SkinnedMesh;
	public var physics:MMDPhysics;
	public var matrixWorldInv:Matrix4;
	public var materials:Array<MeshBasicMaterial>;

	public function new(mesh:SkinnedMesh, physics:MMDPhysics) {
		super();
		root = mesh;
		this.physics = physics;
		matrix.copy(mesh.matrixWorld);
		matrixAutoUpdate = false;
		materials = [];
		materials.push(new MeshBasicMaterial({
			color: new Color(0xff8888),
			wireframe: true,
			depthTest: false,
			depthWrite: false,
			opacity: 0.25,
			transparent: true
		}));
		materials.push(new MeshBasicMaterial({
			color: new Color(0x88ff88),
			wireframe: true,
			depthTest: false,
			depthWrite: false,
			opacity: 0.25,
			transparent: true
		}));
		materials.push(new MeshBasicMaterial({
			color: new Color(0x8888ff),
			wireframe: true,
			depthTest: false,
			depthWrite: false,
			opacity: 0.25,
			transparent: true
		}));
		_init();
	}

	public function dispose() {
		var materials = this.materials;
		var children = this.children;
		for (i in 0...materials.length) {
			materials[i].dispose();
		}
		for (i in 0...children.length) {
			var child = children[i];
			if (child.isMesh)
				child.geometry.dispose();
		}
	}

	public function updateMatrixWorld(force:Bool) {
		var mesh = root;
		if (visible) {
			var bodies = physics.bodies;
			matrixWorldInv.copy(mesh.matrixWorld)
				.decompose(_position, _quaternion, _scale)
				.compose(_position, _quaternion, _scale.set(1, 1, 1))
				.invert();
			for (i in 0...bodies.length) {
				var body = bodies[i].body;
				var child = children[i];
				var tr = body.getCenterOfMassTransform();
				var origin = tr.getOrigin();
				var rotation = tr.getRotation();
				child.position.set(origin.x(), origin.y(), origin.z()).applyMatrix4(matrixWorldInv);
				child.quaternion.setFromRotationMatrix(matrixWorldInv).multiply(_quaternion.set(rotation.x(), rotation.y(), rotation.z(), rotation.w()));
			}
			matrix.copy(mesh.matrixWorld).decompose(_position, _quaternion, _scale).compose(_position, _quaternion, _scale.set(1, 1, 1));
			super.updateMatrixWorld(force);
		}

		private function _init() {
			var bodies = physics.bodies;
			function createGeometry(param:Dynamic):Geometry {
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
			}
			for (i in 0...bodies.length) {
				var param = bodies[i].params;
				add(new Mesh(createGeometry(param), materials[param.type]));
			}
		}
	}
	export
	{
		MMDPhysics
	};
