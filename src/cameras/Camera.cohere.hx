import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class Camera extends Object3D {

	public var isCamera:Bool = true;
	public var type:String = 'Camera';
	public var matrixWorldInverse:Matrix3D;
	public var projectionMatrix:Matrix3D;
	public var projectionMatrixInverse:Matrix3D;
	public var coordinateSystem:Int;

	public function new() {
		super();
		matrixWorldInverse = new Matrix3D();
		projectionMatrix = new Matrix3D();
		projectionMatrixInverse = new Matrix3D();
		coordinateSystem = WebGLCoordinateSystem;
	}

	public function copy(source:Camera, recursive:Bool = false):Camera {
		super.copy(source, recursive);
		matrixWorldInverse.copyFrom(source.matrixWorldInverse);
		projectionMatrix.copyFrom(source.projectionMatrix);
		projectionMatrixInverse.copyFrom(source.projectionMatrixInverse);
		coordinateSystem = source.coordinateSystem;
		return this;
	}

	public function getWorldDirection(target:Vector3D = null):Vector3D {
		return super.getWorldDirection(target).negate();
	}

	public function updateMatrixWorld(force:Bool = false):Void {
		super.updateMatrixWorld(force);
		matrixWorldInverse.copyFrom(matrixWorld).invert();
	}

	public function updateWorldMatrix(updateParents:Bool = false, updateChildren:Bool = false):Void {
		super.updateWorldMatrix(updateParents, updateChildren);
		matrixWorldInverse.copyFrom(matrixWorld).invert();
	}

	public function clone():Camera {
		return new Camera().copy(this);
	}

}