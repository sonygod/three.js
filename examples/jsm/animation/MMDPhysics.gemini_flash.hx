import three.Bones;
import three.Matrix4;
import three.Mesh;
import three.Object3D;
import three.Quaternion;
import three.SkinnedMesh;
import three.Vector3;
import three.geometries.BoxGeometry;
import three.geometries.CapsuleGeometry;
import three.geometries.SphereGeometry;
import three.materials.MeshBasicMaterial;
import three.math.Color;
import three.math.Euler;
import js.Lib;

@:native("Ammo") extern class Ammo {}

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
class MMDPhysics {

	/**
	 * @param {THREE.SkinnedMesh} mesh
	 * @param {Array<Object>} rigidBodyParams
	 * @param {Array<Object>} (optional) constraintParams
	 * @param {Object} params - (optional)
	 * @param {Number} params.unitStep - Default is 1 / 65.
	 * @param {Integer} params.maxStepNum - Default is 3.
	 * @param {Vector3} params.gravity - Default is ( 0, - 9.8 * 10, 0 )
	 */
	public function new(mesh:SkinnedMesh, rigidBodyParams:Array<Dynamic>, constraintParams:Array<Dynamic> = null, params:Dynamic = null) {

		if (Ammo == null) {

			throw new Error("THREE.MMDPhysics: Import ammo.js https://github.com/kripken/ammo.js");

		}

		this.manager = new ResourceManager();

		this.mesh = mesh;

		/*
		 * I don't know why but 1/60 unitStep easily breaks models
		 * so I set it 1/65 so far.
		 * Don't set too small unitStep because
		 * the smaller unitStep can make the performance worse.
		 */
		this.unitStep = (params != null && params.unitStep != null) ? params.unitStep : 1 / 65;
		this.maxStepNum = (params != null && params.maxStepNum != null) ? params.maxStepNum : 3;
		this.gravity = new Vector3(0, -9.8 * 10, 0);

		if (params != null && params.gravity != null) this.gravity.copy(params.gravity);

		this.world = (params != null && params.world != null) ? params.world : null; // experimental

		this.bodies = [];
		this.constraints = [];

		_init(mesh, rigidBodyParams, constraintParams);

	}

	/**
	 * Advances Physics calculation and updates bones.
	 *
	 * @param {Number} delta - time in second
	 * @return {MMDPhysics}
	 */
	public function update(delta:Float):MMDPhysics {

		var manager = this.manager;
		var mesh = this.mesh;

		// rigid bodies and constrains are for
		// mesh's world scale (1, 1, 1).
		// Convert to (1, 1, 1) if it isn't.

		var isNonDefaultScale = false;

		var position = manager.allocThreeVector3();
		var quaternion = manager.allocThreeQuaternion();
		var scale = manager.allocThreeVector3();

		mesh.matrixWorld.decompose(position, quaternion, scale);

		if (scale.x != 1 || scale.y != 1 || scale.z != 1) {

			isNonDefaultScale = true;

		}

		var parent:Object3D = null;

		if (isNonDefaultScale) {

			parent = mesh.parent;

			if (parent != null) mesh.parent = null;

			scale.copy(this.mesh.scale);

			mesh.scale.set(1, 1, 1);
			mesh.updateMatrixWorld(true);

		}

		// calculate physics and update bones

		_updateRigidBodies();
		_stepSimulation(delta);
		_updateBones();

		// restore mesh if converted above

		if (isNonDefaultScale) {

			if (parent != null) mesh.parent = parent;

			mesh.scale.copy(scale);

		}

		manager.freeThreeVector3(scale);
		manager.freeThreeQuaternion(quaternion);
		manager.freeThreeVector3(position);

		return this;

	}

	/**
	 * Resets rigid bodies transorm to current bone's.
	 *
	 * @return {MMDPhysics}
	 */
	public function reset():MMDPhysics {

		for (i in 0...this.bodies.length) {

			this.bodies[i].reset();

		}

		return this;

	}

	/**
	 * Warm ups Rigid bodies. Calculates cycles steps.
	 *
	 * @param {Integer} cycles
	 * @return {MMDPhysics}
	 */
	public function warmup(cycles:Int):MMDPhysics {

		for (i in 0...cycles) {

			update(1 / 60);

		}

		return this;

	}

	/**
	 * Sets gravity.
	 *
	 * @param {Vector3} gravity
	 * @return {MMDPhysicsHelper}
	 */
	public function setGravity(gravity:Vector3):MMDPhysics {

		this.world.setGravity(new Ammo.btVector3(gravity.x, gravity.y, gravity.z));
		this.gravity.copy(gravity);

		return this;

	}

	/**
	 * Creates MMDPhysicsHelper
	 *
	 * @return {MMDPhysicsHelper}
	 */
	public function createHelper():MMDPhysicsHelper {

		return new MMDPhysicsHelper(this.mesh, this);

	}

	// private methods

	function _init(mesh:SkinnedMesh, rigidBodyParams:Array<Dynamic>, constraintParams:Array<Dynamic>):Void {

		var manager = this.manager;

		// rigid body/constraint parameters are for
		// mesh's default world transform as position(0, 0, 0),
		// quaternion(0, 0, 0, 1) and scale(0, 0, 0)

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

			this.world = _createWorld();
			setGravity(this.gravity);

		}

		_initRigidBodies(rigidBodyParams);
		_initConstraints(constraintParams);

		if (parent != null) mesh.parent = parent;

		mesh.position.copy(currentPosition);
		mesh.quaternion.copy(currentQuaternion);
		mesh.scale.copy(currentScale);

		mesh.updateMatrixWorld(true);

		reset();

		manager.freeThreeVector3(currentPosition);
		manager.freeThreeQuaternion(currentQuaternion);
		manager.freeThreeVector3(currentScale);

	}

	function _createWorld():Dynamic {

		var config = new Ammo.btDefaultCollisionConfiguration();
		var dispatcher = new Ammo.btCollisionDispatcher(config);
		var cache = new Ammo.btDbvtBroadphase();
		var solver = new Ammo.btSequentialImpulseConstraintSolver();
		var world = new Ammo.btDiscreteDynamicsWorld(dispatcher, cache, solver, config);
		return world;

	}

	function _initRigidBodies(rigidBodies:Array<Dynamic>):Void {

		for (i in 0...rigidBodies.length) {

			this.bodies.push(new RigidBody(
				this.mesh, this.world, rigidBodies[i], this.manager));

		}

	}

	function _initConstraints(constraints:Array<Dynamic>):Void {

		if (constraints == null) return;
		
		for (i in 0...constraints.length) {

			var params = constraints[i];
			var bodyA = this.bodies[params.rigidBodyIndex1];
			var bodyB = this.bodies[params.rigidBodyIndex2];
			this.constraints.push(new Constraint(this.mesh, this.world, bodyA, bodyB, params, this.manager));

		}

	}

	function _stepSimulation(delta:Float):Void {

		var unitStep = this.unitStep;
		var stepTime = delta;
		var maxStepNum = Std.int((delta / unitStep)) + 1;

		if (stepTime < unitStep) {

			stepTime = unitStep;
			maxStepNum = 1;

		}

		if (maxStepNum > this.maxStepNum) {

			maxStepNum = this.maxStepNum;

		}

		this.world.stepSimulation(stepTime, maxStepNum, unitStep);

	}

	function _updateRigidBodies():Void {

		for (i in 0...this.bodies.length) {

			this.bodies[i].updateFromBone();

		}

	}

	function _updateBones():Void {

		for (i in 0...this.bodies.length) {

			this.bodies[i].updateBone();

		}

	}

	public var mesh:SkinnedMesh;
	public var unitStep:Float;
	public var maxStepNum:Int;
	public var gravity:Vector3;
	public var world:Dynamic;
	public var bodies:Array<RigidBody>;
	public var constraints:Array<Constraint>;
	public var manager:ResourceManager;

}

/**
 * This manager's responsibilies are
 *
 * 1. manage Ammo.js and Three.js object resources and
 *    improve the performance and the memory consumption by
 *    reusing objects.
 *
 * 2. provide simple Ammo object operations.
 */
class ResourceManager {

	public function new() {

		// for Three.js
		this.threeVector3s = [];
		this.threeMatrix4s = [];
		this.threeQuaternions = [];
		this.threeEulers = [];

		// for Ammo.js
		this.transforms = [];
		this.quaternions = [];
		this.vector3s = [];

	}

	public function allocThreeVector3():Vector3 {

		if (this.threeVector3s.length > 0) {
			return this.threeVector3s.pop();
		} else {
			return new Vector3();
		}

	}

	public function freeThreeVector3(v:Vector3):Void {

		this.threeVector3s.push(v);

	}

	public function allocThreeMatrix4():Matrix4 {
		
		if (this.threeMatrix4s.length > 0) {
			return this.threeMatrix4s.pop();
		} else {
			return new Matrix4();
		}
		

	}

	public function freeThreeMatrix4(m:Matrix4):Void {

		this.threeMatrix4s.push(m);

	}

	public function allocThreeQuaternion():Quaternion {

		if (this.threeQuaternions.length > 0) {
			return this.threeQuaternions.pop();
		} else {
			return new Quaternion();
		}

	}

	public function freeThreeQuaternion(q:Quaternion):Void {

		this.threeQuaternions.push(q);

	}

	public function allocThreeEuler():Euler {
		
		if (this.threeEulers.length > 0) {
			return this.threeEulers.pop();
		} else {
			return new Euler();
		}

	}

	public function freeThreeEuler(e:Euler):Void {

		this.threeEulers.push(e);

	}

	public function allocTransform():Dynamic {
		
		if (this.transforms.length > 0) {
			return this.transforms.pop();
		} else {
			return new Ammo.btTransform();
		}

	}

	public function freeTransform(t:Dynamic):Void {

		this.transforms.push(t);

	}

	public function allocQuaternion():Dynamic {
		
		if (this.quaternions.length > 0) {
			return this.quaternions.pop();
		} else {
			return new Ammo.btQuaternion();
		}

	}

	public function freeQuaternion(q:Dynamic):Void {

		this.quaternions.push(q);

	}

	public function allocVector3():Dynamic {

		if (this.vector3s.length > 0) {
			return this.vector3s.pop();
		} else {
			return new Ammo.btVector3();
		}

	}

	public function freeVector3(v:Dynamic):Void {

		this.vector3s.push(v);

	}

	public function setIdentity(t:Dynamic):Void {

		t.setIdentity();

	}

	public function getBasis(t:Dynamic):Dynamic {

		var q = allocQuaternion();
		t.getBasis().getRotation(q);
		return q;

	}

	public function getBasisAsMatrix3(t:Dynamic):Array<Float> {

		var q = getBasis(t);
		var m = quaternionToMatrix3(q);
		freeQuaternion(q);
		return m;

	}

	public function getOrigin(t:Dynamic):Dynamic {

		return t.getOrigin();

	}

	public function setOrigin(t:Dynamic, v:Dynamic):Void {

		t.getOrigin().setValue(v.x(), v.y(), v.z());

	}

	public function copyOrigin(t1:Dynamic, t2:Dynamic):Void {

		var o = t2.getOrigin();
		setOrigin(t1, o);

	}

	public function setBasis(t:Dynamic, q:Dynamic):Void {

		t.setRotation(q);

	}

	public function setBasisFromMatrix3(t:Dynamic, m:Array<Float>):Void {

		var q = matrix3ToQuaternion(m);
		setBasis(t, q);
		freeQuaternion(q);

	}

	public function setOriginFromArray3(t:Dynamic, a:Array<Float>):Void {

		t.getOrigin().setValue(a[0], a[1], a[2]);

	}

	public function setOriginFromThreeVector3(t:Dynamic, v:Vector3):Void {

		t.getOrigin().setValue(v.x, v.y, v.z);

	}

	public function setBasisFromArray3(t:Dynamic, a:Array<Float>):Void {

		var thQ = allocThreeQuaternion();
		var thE = allocThreeEuler();
		thE.set(a[0], a[1], a[2]);
		setBasisFromThreeQuaternion(t, thQ.setFromEuler(thE));

		freeThreeEuler(thE);
		freeThreeQuaternion(thQ);

	}

	public function setBasisFromThreeQuaternion(t:Dynamic, a:Quaternion):Void {

		var q = allocQuaternion();

		q.setX(a.x);
		q.setY(a.y);
		q.setZ(a.z);
		q.setW(a.w);
		setBasis(t, q);

		freeQuaternion(q);

	}

	public function multiplyTransforms(t1:Dynamic, t2:Dynamic):Dynamic {

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

	public function inverseTransform(t:Dynamic):Dynamic {

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

	public function addVector3(v1:Dynamic, v2:Dynamic):Dynamic {

		var v = allocVector3();
		v.setValue(v1.x() + v2.x(), v1.y() + v2.y(), v1.z() + v2.z());
		return v;

	}

	public function dotVectors3(v1:Dynamic, v2:Dynamic):Float {

		return v1.x() * v2.x() + v1.y() * v2.y() + v1.z() * v2.z();

	}

	public function rowOfMatrix3(m:Array<Float>, i:Int):Dynamic {

		var v = allocVector3();
		v.setValue(m[i * 3 + 0], m[i * 3 + 1], m[i * 3 + 2]);
		return v;

	}

	public function columnOfMatrix3(m:Array<Float>, i:Int):Dynamic {

		var v = allocVector3();
		v.setValue(m[i + 0], m[i + 3], m[i + 6]);
		return v;

	}

	public function negativeVector3(v:Dynamic):Dynamic {

		var v2 = allocVector3();
		v2.setValue(-v.x(), -v.y(), -v.z());
		return v2;

	}

	public function multiplyMatrix3ByVector3(m:Array<Float>, v:Dynamic):Dynamic {

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

		var q = allocQuaternion();
		q.setX(x);
		q.setY(y);
		q.setZ(z);
		q.setW(w);
		return q;

	}

	public var threeVector3s:Array<Vector3>;
	public var threeMatrix4s:Array<Matrix4>;
	public var threeQuaternions:Array<Quaternion>;
	public var threeEulers:Array<Euler>;
	public var transforms:Array<Dynamic>;
	public var quaternions:Array<Dynamic>;
	public var vector3s:Array<Dynamic>;

}

/**
 * @param {THREE.SkinnedMesh} mesh
 * @param {Ammo.btDiscreteDynamicsWorld} world
 * @param {Object} params
 * @param {ResourceManager} manager
 */
class RigidBody {

	public function new(mesh:SkinnedMesh, world:Dynamic, params:Dynamic, manager:ResourceManager) {

		this.mesh = mesh;
		this.world = world;
		this.params = params;
		this.manager = manager;

		this.body = null;
		this.bone = null;
		this.boneOffsetForm = null;
		this.boneOffsetFormInverse = null;

		_init();

	}

	/**
	 * Resets rigid body transform to the current bone's.
	 *
	 * @return {RigidBody}
	 */
	public function reset():RigidBody {

		_setTransformFromBone();
		return this;

	}

	/**
	 * Updates rigid body's transform from the current bone.
	 *
	 * @return {RidigBody}
	 */
	public function updateFromBone():RigidBody {

		if (this.params.boneIndex != -1 && this.params.type == 0) {

			_setTransformFromBone();

		}

		return this;

	}

	/**
	 * Updates bone from the current ridid body's transform.
	 *
	 * @return {RidigBody}
	 */
	public function updateBone():RigidBody {

		if (this.params.type == 0 || this.params.boneIndex == -1) {

			return this;

		}

		_updateBoneRotation();

		if (this.params.type == 1) {

			_updateBonePosition();

		}

		this.bone.updateMatrixWorld(true);

		if (this.params.type == 2) {

			_setPositionFromBone();

		}

		return this;

	}

	// private methods

	function _init():Void {

		function generateShape(p:Dynamic):Dynamic {

			switch (p.shapeType) {

				case 0:
					return new Ammo.btSphereShape(p.width);

				case 1:
					return new Ammo.btBoxShape(new Ammo.btVector3(p.width, p.height, p.depth));

				case 2:
					return new Ammo.btCapsuleShape(p.width, p.height);

				default:
					throw new Error('unknown shape type ' + p.shapeType);

			}

		}

		var manager = this.manager;
		var params = this.params;
		var bones = this.mesh.skeleton.bones;
		var bone:Bones;

		if (params.boneIndex == -1) {
			bone = new Bones();
		} else {
			bone = bones[params.boneIndex];
		}

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

	function _getBoneTransform():Dynamic {

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

	function _getWorldTransformForBone():Dynamic {

		var manager = this.manager;
		var tr = this.body.getCenterOfMassTransform();
		return manager.multiplyTransforms(tr, this.boneOffsetFormInverse);

	}

	function _setTransformFromBone():Void {

		var manager = this.manager;
		var form = _getBoneTransform();

		// TODO: check the most appropriate way to set
		//this.body.setWorldTransform( form );
		this.body.setCenterOfMassTransform(form);
		this.body.getMotionState().setWorldTransform(form);

		manager.freeTransform(form);

	}

	function _setPositionFromBone():Void {

		var manager = this.manager;
		var form = _getBoneTransform();

		var tr = manager.allocTransform();
		this.body.getMotionState().getWorldTransform(tr);
		manager.copyOrigin(tr, form);

		// TODO: check the most appropriate way to set
		//this.body.setWorldTransform( tr );
		this.body.setCenterOfMassTransform(tr);
		this.body.getMotionState().setWorldTransform(tr);

		manager.freeTransform(tr);
		manager.freeTransform(form);

	}

	function _updateBoneRotation():Void {

		var manager = this.manager;

		var tr = _getWorldTransformForBone();
		var q = manager.getBasis(tr);

		var thQ = manager.allocThreeQuaternion();
		var thQ2 = manager.allocThreeQuaternion();
		var thQ3 = manager.allocThreeQuaternion();

		thQ.set(q.x(), q.y(), q.z(), q.w());
		thQ2.setFromRotationMatrix(this.bone.matrixWorld);
		thQ2.conjugate();
		thQ2.multiply(thQ);

		//this.bone.quaternion.multiply( thQ2 );

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

	function _updateBonePosition():Void {

		var manager = this.manager;

		var tr = _getWorldTransformForBone();

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

	public var mesh:SkinnedMesh;
	public var world:Dynamic;
	public var params:Dynamic;
	public var manager:ResourceManager;
	public var body:Dynamic;
	public var bone:Bones;
	public var boneOffsetForm:Dynamic;
	
	public var boneOffsetFormInverse:Dynamic;

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
	public function new(mesh:SkinnedMesh, world:Dynamic, bodyA:RigidBody, bodyB:RigidBody, params:Dynamic, manager:ResourceManager) {

		this.mesh = mesh;
		this.world = world;
		this.bodyA = bodyA;
		this.bodyB = bodyB;
		this.params = params;
		this.manager = manager;

		this.constraint = null;

		_init();

	}

	// private method

	function _init():Void {

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
		if (Reflect.hasField(constraint, "setParam")) {

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

	public var mesh:SkinnedMesh;
	public var world:Dynamic;
	public var bodyA:RigidBody;
	public var bodyB:RigidBody;
	public var params:Dynamic;
	public var manager:ResourceManager;
	public var constraint:Dynamic;

}

//

var _position = new Vector3();
var _quaternion = new Quaternion();
var _scale = new Vector3();
var _matrixWorldInv = new Matrix4();

class MMDPhysicsHelper extends Object3D {

	/**
	 * Visualize Rigid bodies
	 *
	 * @param {THREE.SkinnedMesh} mesh
	 * @param {Physics} physics
	 */
	public function new(mesh:SkinnedMesh, physics:MMDPhysics) {

		super();

		this.root = mesh;
		this.physics = physics;

		this.matrix.copy(mesh.matrixWorld);
		this.matrixAutoUpdate = false;

		this.materials = [];

		this.materials.push(
			new MeshBasicMaterial({
				color: new Color(0xff8888),
				wireframe: true,
				depthTest: false,
				depthWrite: false,
				opacity: 0.25,
				transparent: true
			})
		);

		this.materials.push(
			new MeshBasicMaterial({
				color: new Color(0x88ff88),
				wireframe: true,
				depthTest: false,
				depthWrite: false,
				opacity: 0.25,
				transparent: true
			})
		);

		this.materials.push(
			new MeshBasicMaterial({
				color: new Color(0x8888ff),
				wireframe: true,
				depthTest: false,
				depthWrite: false,
				opacity: 0.25,
				transparent: true
			})
		);

		_init();

	}

	/**
	 * Frees the GPU-related resources allocated by this instance. Call this method whenever this instance is no longer used in your app.
	 */
	public function dispose():Void {

		var materials = this.materials;
		var children = this.children;

		for (i in 0...materials.length) {

			materials[i].dispose();

		}

		for (i in 0...children.length) {

			var child = cast(children[i], Mesh);

			if (child != null) child.geometry.dispose();

		}

	}

	/**
	 * Updates Rigid Bodies visualization.
	 */
	override public function updateMatrixWorld(force:Bool):Void {

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
				var child = cast(this.children[i], Object3D);

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

	function _init():Void {

		var bodies = this.physics.bodies;

		function createGeometry(param:Dynamic):Dynamic {

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
			this.add(new Mesh(createGeometry(param), this.materials[param.type]));

		}

	}

	public var root:SkinnedMesh;
	public var physics:MMDPhysics;
	public var materials:Array<MeshBasicMaterial>;
}