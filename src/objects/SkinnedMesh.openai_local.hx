import three.objects.Mesh;
import three.math.Box3;
import three.math.Matrix4;
import three.math.Sphere;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Ray;
import three.constants.AttachedBindMode;
import three.constants.DetachedBindMode;

class SkinnedMesh extends Mesh {

	public var isSkinnedMesh:Bool;
	public var bindMode:String;
	public var bindMatrix:Matrix4;
	public var bindMatrixInverse:Matrix4;
	public var boundingBox:Box3;
	public var boundingSphere:Sphere;
	public var skeleton:Skeleton;

	static var _basePosition:Vector3 = new Vector3();
	static var _skinIndex:Vector4 = new Vector4();
	static var _skinWeight:Vector4 = new Vector4();
	static var _vector3:Vector3 = new Vector3();
	static var _matrix4:Matrix4 = new Matrix4();
	static var _vertex:Vector3 = new Vector3();
	static var _sphere:Sphere = new Sphere();
	static var _inverseMatrix:Matrix4 = new Matrix4();
	static var _ray:Ray = new Ray();

	public function new(geometry:Geometry, material:Material) {
		super(geometry, material);
		this.isSkinnedMesh = true;
		this.type = 'SkinnedMesh';
		this.bindMode = AttachedBindMode;
		this.bindMatrix = new Matrix4();
		this.bindMatrixInverse = new Matrix4();
		this.boundingBox = null;
		this.boundingSphere = null;
	}

	public function computeBoundingBox():Void {
		if (this.boundingBox == null) {
			this.boundingBox = new Box3();
		}
		this.boundingBox.makeEmpty();
		var positionAttribute = this.geometry.getAttribute('position');
		for (i in 0...positionAttribute.count) {
			this.getVertexPosition(i, _vertex);
			this.boundingBox.expandByPoint(_vertex);
		}
	}

	public function computeBoundingSphere():Void {
		if (this.boundingSphere == null) {
			this.boundingSphere = new Sphere();
		}
		this.boundingSphere.makeEmpty();
		var positionAttribute = this.geometry.getAttribute('position');
		for (i in 0...positionAttribute.count) {
			this.getVertexPosition(i, _vertex);
			this.boundingSphere.expandByPoint(_vertex);
		}
	}

	public function copy(source:SkinnedMesh, recursive:Bool):SkinnedMesh {
		super.copy(source, recursive);
		this.bindMode = source.bindMode;
		this.bindMatrix.copy(source.bindMatrix);
		this.bindMatrixInverse.copy(source.bindMatrixInverse);
		this.skeleton = source.skeleton;
		if (source.boundingBox != null) this.boundingBox = source.boundingBox.clone();
		if (source.boundingSphere != null) this.boundingSphere = source.boundingSphere.clone();
		return this;
	}

	public function raycast(raycaster:Raycaster, intersects:Array<Intersection>):Void {
		var material = this.material;
		var matrixWorld = this.matrixWorld;
		if (material == null) return;
		if (this.boundingSphere == null) this.computeBoundingSphere();
		_sphere.copy(this.boundingSphere);
		_sphere.applyMatrix4(matrixWorld);
		if (!raycaster.ray.intersectsSphere(_sphere)) return;
		_inverseMatrix.copy(matrixWorld).invert();
		_ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);
		if (this.boundingBox != null) {
			if (!_ray.intersectsBox(this.boundingBox)) return;
		}
		this._computeIntersections(raycaster, intersects, _ray);
	}

	public function getVertexPosition(index:Int, target:Vector3):Vector3 {
		super.getVertexPosition(index, target);
		this.applyBoneTransform(index, target);
		return target;
	}

	public function bind(skeleton:Skeleton, bindMatrix:Matrix4 = null):Void {
		this.skeleton = skeleton;
		if (bindMatrix == null) {
			this.updateMatrixWorld(true);
			this.skeleton.calculateInverses();
			bindMatrix = this.matrixWorld;
		}
		this.bindMatrix.copy(bindMatrix);
		this.bindMatrixInverse.copy(bindMatrix).invert();
	}

	public function pose():Void {
		this.skeleton.pose();
	}

	public function normalizeSkinWeights():Void {
		var vector = new Vector4();
		var skinWeight = this.geometry.attributes.skinWeight;
		for (i in 0...skinWeight.count) {
			vector.fromBufferAttribute(skinWeight, i);
			var scale = 1.0 / vector.manhattanLength();
			if (scale != Math.POSITIVE_INFINITY) {
				vector.multiplyScalar(scale);
			} else {
				vector.set(1, 0, 0, 0);
			}
			skinWeight.setXYZW(i, vector.x, vector.y, vector.z, vector.w);
		}
	}

	public function updateMatrixWorld(force:Bool):Void {
		super.updateMatrixWorld(force);
		if (this.bindMode == AttachedBindMode) {
			this.bindMatrixInverse.copy(this.matrixWorld).invert();
		} else if (this.bindMode == DetachedBindMode) {
			this.bindMatrixInverse.copy(this.bindMatrix).invert();
		} else {
			trace('THREE.SkinnedMesh: Unrecognized bindMode: ' + this.bindMode);
		}
	}

	public function applyBoneTransform(index:Int, vector:Vector3):Vector3 {
		var skeleton = this.skeleton;
		var geometry = this.geometry;
		_skinIndex.fromBufferAttribute(geometry.attributes.skinIndex, index);
		_skinWeight.fromBufferAttribute(geometry.attributes.skinWeight, index);
		_basePosition.copy(vector).applyMatrix4(this.bindMatrix);
		vector.set(0, 0, 0);
		for (i in 0...4) {
			var weight = _skinWeight.getComponent(i);
			if (weight != 0) {
				var boneIndex = _skinIndex.getComponent(i);
				_matrix4.multiplyMatrices(skeleton.bones[boneIndex].matrixWorld, skeleton.boneInverses[boneIndex]);
				vector.addScaledVector(_vector3.copy(_basePosition).applyMatrix4(_matrix4), weight);
			}
		}
		return vector.applyMatrix4(this.bindMatrixInverse);
	}

	private function _computeIntersections(raycaster:Raycaster, intersects:Array<Intersection>, ray:Ray):Void {
		// Add the method logic here
	}

}