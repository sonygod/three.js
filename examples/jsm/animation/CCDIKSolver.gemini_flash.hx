package ;

import three.core.Object3D;
import three.objects.Mesh;
import three.objects.Line;
import three.core.BufferGeometry;
import three.materials.Material;
import three.materials.LineBasicMaterial;
import three.materials.MeshBasicMaterial;
import three.geometries.SphereGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;
import three.math.Quaternion;
import three.math.Matrix4;
import three.math.Euler;
import three.objects.SkinnedMesh;
import three.core.Float32BufferAttribute;

class CCDIKSolver {

	public var mesh(default, null) : SkinnedMesh;
	public var iks(default, null) : Array<IK>;
	
	static var _q = new Quaternion();
	static var _targetPos = new Vector3();
	static var _targetVec = new Vector3();
	static var _effectorPos = new Vector3();
	static var _effectorVec = new Vector3();
	static var _linkPos = new Vector3();
	static var _invLinkQ = new Quaternion();
	static var _linkScale = new Vector3();
	static var _axis = new Vector3();
	static var _vector = new Vector3();
	static var _matrix = new Matrix4();
	

	/**
	 * CCD Algorithm
	 *  - https://sites.google.com/site/auraliusproject/ccd-algorithm
	 *
	 * // ik parameter example
	 * //
	 * // target, effector, index in links are bone index in skeleton.bones.
	 * // the bones relation should be
	 * // <-- parent                                  child -->
	 * // links[ n ], links[ n - 1 ], ..., links[ 0 ], effector
	 * iks = [ {
	 *	target: 1,
	 *	effector: 2,
	 *	links: [ { index: 5, limitation: new Vector3( 1, 0, 0 ) }, { index: 4, enabled: false }, { index : 3 } ],
	 *	iteration: 10,
	 *	minAngle: 0.0,
	 *	maxAngle: 1.0,
	 * } ];
	 */
	public function new(mesh : SkinnedMesh, iks : Array<IK> = null) {
		
		if(iks == null) iks = [];
		this.mesh = mesh;
		this.iks = iks;

		_valid(this.iks, this.mesh);

	}

	/**
	 * Update all IK bones.
	 *
	 * @return {CCDIKSolver}
	 */
	public function update() : CCDIKSolver {
		
		var iks = this.iks;

		for (i in 0...iks.length) {

			updateOne(iks[i]);

		}

		return this;

	}

	/**
	 * Update one IK bone
	 *
	 * @param {IK} ik parameter
	 * @return {CCDIKSolver}
	 */
	public function updateOne(ik : IK) : CCDIKSolver {
		
		var bones = this.mesh.skeleton.bones;

		// for reference overhead reduction in loop
		// var math = Math;

		var effector = bones[ik.effector];
		var target = bones[ik.target];

		// don't use getWorldPosition() here for the performance
		// because it calls updateMatrixWorld( true ) inside.
		_targetPos.setFromMatrixPosition(target.matrixWorld);

		var links = ik.links;
		var iteration = (ik.iteration != null) ? ik.iteration : 1;

		for (i in 0...iteration) {
			
			var rotated = false;

			for (j in 0...links.length) {

				var link = bones[links[j].index];

				// skip this link and following links.
				// this skip is used for MMD performance optimization.
				if (links[j].enabled == false) {
					break;
				}

				var limitation = links[j].limitation;
				var rotationMin = links[j].rotationMin;
				var rotationMax = links[j].rotationMax;

				// don't use getWorldPosition/Quaternion() here for the performance
				// because they call updateMatrixWorld( true ) inside.
				link.matrixWorld.decompose(_linkPos, _invLinkQ, _linkScale);
				_invLinkQ.invert();
				_effectorPos.setFromMatrixPosition(effector.matrixWorld);

				// work in link world
				_effectorVec.subVectors(_effectorPos, _linkPos);
				_effectorVec.applyQuaternion(_invLinkQ);
				_effectorVec.normalize();

				_targetVec.subVectors(_targetPos, _linkPos);
				_targetVec.applyQuaternion(_invLinkQ);
				_targetVec.normalize();

				var angle = _targetVec.dot(_effectorVec);

				if (angle > 1.0) {

					angle = 1.0;

				} else if (angle < -1.0) {

					angle = -1.0;

				}

				angle = Math.acos(angle);

				// skip if changing angle is too small to prevent vibration of bone
				if (angle < 1e-5) {
					continue;
				}

				if (ik.minAngle != null && angle < ik.minAngle) {

					angle = ik.minAngle;

				}

				if (ik.maxAngle != null && angle > ik.maxAngle) {

					angle = ik.maxAngle;

				}

				_axis.crossVectors(_effectorVec, _targetVec);
				_axis.normalize();

				_q.setFromAxisAngle(_axis, angle);
				link.quaternion.multiply(_q);

				// TODO: re-consider the limitation specification
				if (limitation != null) {

					var c = link.quaternion.w;

					if (c > 1.0) {
						c = 1.0;
					}

					var c2 = Math.sqrt(1 - c * c);
					link.quaternion.set(limitation.x * c2,
					                    limitation.y * c2,
					                    limitation.z * c2,
					                    c);

				}

				if (rotationMin != null) {
					
					_vector.setFromEuler(link.rotation);
					_vector.max(rotationMin);
					link.rotation.setFromVector3(_vector);

				}

				if (rotationMax != null) {

					_vector.setFromEuler(link.rotation);
					_vector.min(rotationMax);
					link.rotation.setFromVector3(_vector);
				}

				link.updateMatrixWorld(true);

				rotated = true;

			}

			if (!rotated) {
				break;
			}

		}

		return this;

	}

	/**
	 * Creates Helper
	 *
	 * @param {Float} sphereSize
	 * @return {CCDIKHelper}
	 */
	public function createHelper(sphereSize : Float) : CCDIKHelper {

		return new CCDIKHelper(this.mesh, this.iks, sphereSize);

	}

	// private methods

	static function _valid(iks : Array<IK>, mesh : SkinnedMesh) : Void {
		
		var bones = mesh.skeleton.bones;

		for (i in 0...iks.length) {

			var ik = iks[i];
			var effector = bones[ik.effector];
			var links = ik.links;
			var link0, link1;

			link0 = effector;

			for (j in 0...links.length) {

				link1 = bones[links[j].index];

				if (link0.parent != link1) {

					trace('THREE.CCDIKSolver: bone ' + link0.name + ' is not the child of bone ' + link1.name);

				}

				link0 = link1;

			}

		}

	}

}

function getPosition(bone : Bone, matrixWorldInv : Matrix4) : Vector3 {

	var _vector = new Vector3();
	return _vector
		.setFromMatrixPosition(bone.matrixWorld)
		.applyMatrix4(matrixWorldInv);

}

function setPositionOfBoneToAttributeArray(array : Array<Float>, index : Int, bone : Bone, matrixWorldInv : Matrix4) : Void {

	var v = getPosition(bone, matrixWorldInv);

	array[index * 3 + 0] = v.x;
	array[index * 3 + 1] = v.y;
	array[index * 3 + 2] = v.z;

}

/**
 * Visualize IK bones
 *
 * @param {SkinnedMesh} mesh
 * @param {Array<IK>} iks
 * @param {Float} sphereSize
 */
class CCDIKHelper extends Object3D {

	var root : SkinnedMesh;
	var iks : Array<IK>;
	var sphereGeometry : SphereGeometry;
	var targetSphereMaterial : MeshBasicMaterial;
	var effectorSphereMaterial : MeshBasicMaterial;
	var linkSphereMaterial : MeshBasicMaterial;
	var lineMaterial : LineBasicMaterial;

	public function new(mesh : SkinnedMesh, iks : Array<IK> = null, sphereSize : Float = 0.25) {
		
		super();

		this.root = mesh;
		
		if (iks == null) iks = [];
		this.iks = iks;
		
		this.matrix.copy(mesh.matrixWorld);
		this.matrixAutoUpdate = false;

		this.sphereGeometry = new SphereGeometry(sphereSize, 16, 8);

		this.targetSphereMaterial = new MeshBasicMaterial( {
			color: 0xff8888,
			depthTest: false,
			depthWrite: false,
			transparent: true
		} );

		this.effectorSphereMaterial = new MeshBasicMaterial( {
			color: 0x88ff88,
			depthTest: false,
			depthWrite: false,
			transparent: true
		} );

		this.linkSphereMaterial = new MeshBasicMaterial( {
			color: 0x8888ff,
			depthTest: false,
			depthWrite: false,
			transparent: true
		} );

		this.lineMaterial = new LineBasicMaterial( {
			color: 0xff0000,
			depthTest: false,
			depthWrite: false,
			transparent: true
		} );

		_init();

	}

	/**
	 * Updates IK bones visualization.
	 */
	override public function updateMatrixWorld(force : Bool) : Void {

		var mesh = this.root;

		if (this.visible) {

			var offset = 0;

			var iks = this.iks;
			var bones = mesh.skeleton.bones;

			CCDIKSolver._matrix.copy(mesh.matrixWorld).invert();

			for (i in 0...iks.length) {

				var ik = iks[i];

				var targetBone = bones[ik.target];
				var effectorBone = bones[ik.effector];

				var targetMesh = cast(this.children[offset++], Mesh);
				var effectorMesh = cast(this.children[offset++], Mesh);

				targetMesh.position.copy(getPosition(targetBone, CCDIKSolver._matrix));
				effectorMesh.position.copy(getPosition(effectorBone, CCDIKSolver._matrix));

				for (j in 0...ik.links.length) {

					var link = ik.links[j];
					var linkBone = bones[link.index];

					var linkMesh = cast(this.children[offset++], Mesh);

					linkMesh.position.copy(getPosition(linkBone, CCDIKSolver._matrix));

				}

				var line = cast(this.children[offset++], Line);
				var array = cast(line.geometry.attributes.position, Float32BufferAttribute).array;

				setPositionOfBoneToAttributeArray(array, 0, targetBone, CCDIKSolver._matrix);
				setPositionOfBoneToAttributeArray(array, 1, effectorBone, CCDIKSolver._matrix);

				for (j in 0...ik.links.length) {

					var link = ik.links[j];
					var linkBone = bones[link.index];
					setPositionOfBoneToAttributeArray(array, j + 2, linkBone, CCDIKSolver._matrix);

				}

				line.geometry.attributes.position.needsUpdate = true;

			}

		}

		this.matrix.copy(mesh.matrixWorld);

		super.updateMatrixWorld(force);

	}

	/**
	 * Frees the GPU-related resources allocated by this instance. Call this method whenever this instance is no longer used in your app.
	 */
	public function dispose() : Void {

		sphereGeometry.dispose();

		targetSphereMaterial.dispose();
		effectorSphereMaterial.dispose();
		linkSphereMaterial.dispose();
		lineMaterial.dispose();

		for (i in 0...this.children.length) {

			var child = this.children[i];

			if (Std.isOfType(child, Line)) {
				cast(child, Line).geometry.dispose();
			}
		}

	}

	// private method

	function _init() : Void {

		var scope = this;
		var iks = this.iks;

		function createLineGeometry(ik : IK) : BufferGeometry {

			var geometry = new BufferGeometry();
			var vertices = new Float32Array((2 + ik.links.length) * 3);
			geometry.setAttribute('position', new BufferAttribute(vertices, 3));

			return geometry;

		}

		function createTargetMesh() : Mesh {

			return new Mesh(scope.sphereGeometry, scope.targetSphereMaterial);

		}

		function createEffectorMesh() : Mesh {

			return new Mesh(scope.sphereGeometry, scope.effectorSphereMaterial);

		}

		function createLinkMesh() : Mesh {

			return new Mesh(scope.sphereGeometry, scope.linkSphereMaterial);

		}

		function createLine(ik : IK) : Line {

			return new Line(createLineGeometry(ik), scope.lineMaterial);

		}

		for (i in 0...iks.length) {

			var ik = iks[i];

			this.add(createTargetMesh());
			this.add(createEffectorMesh());

			for (j in 0...ik.links.length) {

				this.add(createLinkMesh());

			}

			this.add(createLine(ik));

		}

	}

}

typedef IK = {
	var target : Int;
	var effector : Int;
	var links : Array<IKLink>;
	var iteration : Null<Int>;
	var minAngle : Null<Float>;
	var maxAngle : Null<Float>;
}

typedef IKLink = {
	var index : Int;
	var enabled : Null<Bool>;
	var limitation : Null<Vector3>;
	var rotationMin : Null<Vector3>;
	var rotationMax : Null<Vector3>;
}