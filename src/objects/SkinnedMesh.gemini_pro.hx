import three.core.Mesh;
import three.math.Box3;
import three.math.Matrix4;
import three.math.Sphere;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Ray;
import three.constants.AttachedBindMode;
import three.constants.DetachedBindMode;

class SkinnedMesh extends Mesh {

	public var isSkinnedMesh:Bool = true;
	public var type:String = "SkinnedMesh";

	public var bindMode:Int = AttachedBindMode;
	public var bindMatrix:Matrix4 = new Matrix4();
	public var bindMatrixInverse:Matrix4 = new Matrix4();

	public var boundingBox:Box3;
	public var boundingSphere:Sphere;

	public var skeleton:Dynamic;

	public function new(geometry:Dynamic, material:Dynamic) {
		super(geometry, material);

		this.boundingBox = null;
		this.boundingSphere = null;
	}

	public function computeBoundingBox() {
		if (this.boundingBox == null) {
			this.boundingBox = new Box3();
		}

		this.boundingBox.makeEmpty();

		var positionAttribute = this.geometry.getAttribute("position");

		for (var i = 0; i < positionAttribute.count; i++) {
			this.getVertexPosition(i, _vertex);
			this.boundingBox.expandByPoint(_vertex);
		}
	}

	public function computeBoundingSphere() {
		if (this.boundingSphere == null) {
			this.boundingSphere = new Sphere();
		}

		this.boundingSphere.makeEmpty();

		var positionAttribute = this.geometry.getAttribute("position");

		for (var i = 0; i < positionAttribute.count; i++) {
			this.getVertexPosition(i, _vertex);
			this.boundingSphere.expandByPoint(_vertex);
		}
	}

	public function copy(source:SkinnedMesh, recursive:Bool) {
		super.copy(source, recursive);

		this.bindMode = source.bindMode;
		this.bindMatrix.copy(source.bindMatrix);
		this.bindMatrixInverse.copy(source.bindMatrixInverse);

		this.skeleton = source.skeleton;

		if (source.boundingBox != null) this.boundingBox = source.boundingBox.clone();
		if (source.boundingSphere != null) this.boundingSphere = source.boundingSphere.clone();

		return this;
	}

	public function raycast(raycaster:Dynamic, intersects:Dynamic) {
		var material = this.material;
		var matrixWorld = this.matrixWorld;

		if (material == null) return;

		// test with bounding sphere in world space
		if (this.boundingSphere == null) this.computeBoundingSphere();

		_sphere.copy(this.boundingSphere);
		_sphere.applyMatrix4(matrixWorld);

		if (!raycaster.ray.intersectsSphere(_sphere)) return;

		// convert ray to local space of skinned mesh
		_inverseMatrix.copy(matrixWorld).invert();
		_ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);

		// test with bounding box in local space
		if (this.boundingBox != null) {
			if (!_ray.intersectsBox(this.boundingBox)) return;
		}

		// test for intersections with geometry
		this._computeIntersections(raycaster, intersects, _ray);
	}

	public function getVertexPosition(index:Int, target:Vector3) {
		super.getVertexPosition(index, target);
		this.applyBoneTransform(index, target);
		return target;
	}

	public function bind(skeleton:Dynamic, bindMatrix:Matrix4) {
		this.skeleton = skeleton;

		if (bindMatrix == null) {
			this.updateMatrixWorld(true);
			this.skeleton.calculateInverses();
			bindMatrix = this.matrixWorld;
		}

		this.bindMatrix.copy(bindMatrix);
		this.bindMatrixInverse.copy(bindMatrix).invert();
	}

	public function pose() {
		this.skeleton.pose();
	}

	public function normalizeSkinWeights() {
		var vector = new Vector4();
		var skinWeight = this.geometry.attributes.skinWeight;

		for (var i = 0; i < skinWeight.count; i++) {
			vector.fromBufferAttribute(skinWeight, i);

			var scale = 1.0 / vector.manhattanLength();

			if (scale != Infinity) {
				vector.multiplyScalar(scale);
			} else {
				vector.set(1, 0, 0, 0); // do something reasonable
			}

			skinWeight.setXYZW(i, vector.x, vector.y, vector.z, vector.w);
		}
	}

	public function updateMatrixWorld(force:Bool) {
		super.updateMatrixWorld(force);

		if (this.bindMode == AttachedBindMode) {
			this.bindMatrixInverse.copy(this.matrixWorld).invert();
		} else if (this.bindMode == DetachedBindMode) {
			this.bindMatrixInverse.copy(this.bindMatrix).invert();
		} else {
			// TODO: Implement console.warn
			// console.warn("THREE.SkinnedMesh: Unrecognized bindMode: " + this.bindMode);
		}
	}

	public function applyBoneTransform(index:Int, vector:Vector3) {
		var skeleton = this.skeleton;
		var geometry = this.geometry;

		_skinIndex.fromBufferAttribute(geometry.attributes.skinIndex, index);
		_skinWeight.fromBufferAttribute(geometry.attributes.skinWeight, index);

		_basePosition.copy(vector).applyMatrix4(this.bindMatrix);

		vector.set(0, 0, 0);

		for (var i = 0; i < 4; i++) {
			var weight = _skinWeight.getComponent(i);

			if (weight != 0) {
				var boneIndex = _skinIndex.getComponent(i);

				_matrix4.multiplyMatrices(skeleton.bones[boneIndex].matrixWorld, skeleton.boneInverses[boneIndex]);
				vector.addScaledVector(_vector3.copy(_basePosition).applyMatrix4(_matrix4), weight);
			}
		}

		return vector.applyMatrix4(this.bindMatrixInverse);
	}

	private function _computeIntersections(raycaster:Dynamic, intersects:Dynamic, ray:Ray):Void {
		// TODO: Implement _computeIntersections
	}

	private static var _basePosition:Vector3 = new Vector3();
	private static var _skinIndex:Vector4 = new Vector4();
	private static var _skinWeight:Vector4 = new Vector4();
	private static var _vector3:Vector3 = new Vector3();
	private static var _matrix4:Matrix4 = new Matrix4();
	private static var _vertex:Vector3 = new Vector3();
	private static var _sphere:Sphere = new Sphere();
	private static var _inverseMatrix:Matrix4 = new Matrix4();
	private static var _ray:Ray = new Ray();
}