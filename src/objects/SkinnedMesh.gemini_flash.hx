import three.core.BufferGeometry;
import three.objects.Mesh;
import three.materials.Material;
import three.math.Vector3;
import three.math.Matrix4;
import three.math.Box3;
import three.math.Sphere;
import three.math.Vector4;
import three.math.Ray;
import three.core.Object3D;
import three.objects.Skeleton;

// Import constants
enum BindMode {
	AttachedBindMode;
	DetachedBindMode;
}

class SkinnedMesh extends Mesh {

	public var isSkinnedMesh:Bool;
	public var bindMode:BindMode;
	public var bindMatrix:Matrix4;
	public var bindMatrixInverse:Matrix4;
	public var skeleton:Skeleton;

	// Private cached variables
	private static var _basePosition:Vector3 = new Vector3();
	private static var _skinIndex:Vector4 = new Vector4();
	private static var _skinWeight:Vector4 = new Vector4();
	private static var _vector3:Vector3 = new Vector3();
	private static var _matrix4:Matrix4 = new Matrix4();
	private static var _vertex:Vector3 = new Vector3();
	private static var _sphere:Sphere = new Sphere();
	private static var _inverseMatrix:Matrix4 = new Matrix4();
	private static var _ray:Ray = new Ray();

	public function new(geometry:BufferGeometry, material:Material) {
		super(geometry, material);

		this.isSkinnedMesh = true;

		this.type = "SkinnedMesh";

		this.bindMode = BindMode.AttachedBindMode;
		this.bindMatrix = new Matrix4();
		this.bindMatrixInverse = new Matrix4();

		this.boundingBox = null;
		this.boundingSphere = null;
	}

	override public function computeBoundingBox():Void {
		var geometry:BufferGeometry = cast this.geometry;

		if (this.boundingBox == null) {
			this.boundingBox = new Box3();
		}

		this.boundingBox.makeEmpty();

		var positionAttribute = geometry.getAttribute("position");

		for (i in 0...positionAttribute.count) {
			this.getVertexPosition(i, _vertex);
			this.boundingBox.expandByPoint(_vertex);
		}
	}

	override public function computeBoundingSphere():Void {
		var geometry = cast this.geometry;

		if (this.boundingSphere == null) {
			this.boundingSphere = new Sphere();
		}

		this.boundingSphere.makeEmpty();

		var positionAttribute = geometry.getAttribute("position");

		for (i in 0...positionAttribute.count) {
			this.getVertexPosition(i, _vertex);
			this.boundingSphere.expandByPoint(_vertex);
		}
	}

	override public function copy(source:Object3D, ?recursive:Bool = true):SkinnedMesh {
		super.copy(source, recursive);

		var src:SkinnedMesh = cast source;
		this.bindMode = src.bindMode;
		this.bindMatrix.copy(src.bindMatrix);
		this.bindMatrixInverse.copy(src.bindMatrixInverse);

		this.skeleton = src.skeleton;

		if (src.boundingBox != null) this.boundingBox = src.boundingBox.clone();
		if (src.boundingSphere != null) this.boundingSphere = src.boundingSphere.clone();

		return this;
	}

	// Assuming raycast function signature remains similar
	// public function raycast(raycaster:Raycaster, intersects:Array<Intersection>):Void {
	//   // Implementation here
	// }

	override public function getVertexPosition(index:Int, target:Vector3):Vector3 {
		super.getVertexPosition(index, target);

		this.applyBoneTransform(index, target);

		return target;
	}

	public function bind(skeleton:Skeleton, ?bindMatrix:Matrix4):Void {
		this.skeleton = skeleton;

		if (bindMatrix == null) {
			this.updateMatrixWorld(true);

			this.skeleton.calculateInverses();

			bindMatrix = this.matrixWorld.clone();
		}

		this.bindMatrix.copy(bindMatrix);
		this.bindMatrixInverse.copy(bindMatrix).invert();
	}

	public function pose():Void {
		this.skeleton.pose();
	}

	public function normalizeSkinWeights():Void {
		var vector = new Vector4();

		var skinWeight = this.geometry.getAttribute("skinWeight");

		for (i in 0...skinWeight.count) {
			vector.fromBufferAttribute(skinWeight, i);

			var scale = 1.0 / vector.manhattanLength();

			if (scale != Math.POSITIVE_INFINITY) {
				vector.multiplyScalar(scale);
			} else {
				vector.set(1, 0, 0, 0); // do something reasonable
			}

			skinWeight.setXYZW(i, vector.x, vector.y, vector.z, vector.w);
		}
	}

	override public function updateMatrixWorld(?force:Bool = false):Void {
		super.updateMatrixWorld(force);

		switch (this.bindMode) {
			case BindMode.AttachedBindMode:
				this.bindMatrixInverse.copy(this.matrixWorld).invert();
			case BindMode.DetachedBindMode:
				this.bindMatrixInverse.copy(this.bindMatrix).invert();
			default:
				trace('THREE.SkinnedMesh: Unrecognized bindMode: $this.bindMode');
		}
	}

	private function applyBoneTransform(index:Int, vector:Vector3):Vector3 {
		var geometry = cast this.geometry;

		_skinIndex.fromBufferAttribute(geometry.getAttribute("skinIndex"), index);
		_skinWeight.fromBufferAttribute(geometry.getAttribute("skinWeight"), index);

		_basePosition.copy(vector).applyMatrix4(this.bindMatrix);

		vector.set(0, 0, 0);

		for (i in 0...4) {
			var weight = _skinWeight.getComponent(i);

			if (weight != 0) {
				var boneIndex = _skinIndex.getComponent(i);

				_matrix4.multiplyMatrices(this.skeleton.bones[boneIndex].matrixWorld, this.skeleton.boneInverses[boneIndex]);

				vector.addScaledVector(_vector3.copy(_basePosition).applyMatrix4(_matrix4), weight);
			}
		}

		return vector.applyMatrix4(this.bindMatrixInverse);
	}
}