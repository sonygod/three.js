import three.js.src.constants.WebGLCoordinateSystem;
import three.js.src.math.Matrix4;
import three.js.src.core.Object3D;

class Camera extends Object3D {

	public var isCamera:Bool = true;
	public var type:String = 'Camera';
	public var matrixWorldInverse:Matrix4 = new Matrix4();
	public var projectionMatrix:Matrix4 = new Matrix4();
	public var projectionMatrixInverse:Matrix4 = new Matrix4();
	public var coordinateSystem:WebGLCoordinateSystem;

	public function new() {
		super();
		this.coordinateSystem = WebGLCoordinateSystem;
	}

	public function copy(source:Camera, recursive:Bool):Camera {
		super.copy(source, recursive);
		this.matrixWorldInverse.copy(source.matrixWorldInverse);
		this.projectionMatrix.copy(source.projectionMatrix);
		this.projectionMatrixInverse.copy(source.projectionMatrixInverse);
		this.coordinateSystem = source.coordinateSystem;
		return this;
	}

	public function getWorldDirection(target:Dynamic):Dynamic {
		return super.getWorldDirection(target).negate();
	}

	public function updateMatrixWorld(force:Bool):Void {
		super.updateMatrixWorld(force);
		this.matrixWorldInverse.copy(this.matrixWorld).invert();
	}

	public function updateWorldMatrix(updateParents:Bool, updateChildren:Bool):Void {
		super.updateWorldMatrix(updateParents, updateChildren);
		this.matrixWorldInverse.copy(this.matrixWorld).invert();
	}

	public function clone():Camera {
		return Type.createEmptyInstance(Type.getClass(this)).copy(this);
	}

}