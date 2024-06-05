import three.js.src.constants.WebGLCoordinateSystem;
import three.js.src.math.Matrix4;
import three.js.src.core.Object3D;

class Camera extends Object3D {

	public function new() {

		super();

		this.isCamera = true;

		this.type = 'Camera';

		this.matrixWorldInverse = new Matrix4();

		this.projectionMatrix = new Matrix4();
		this.projectionMatrixInverse = new Matrix4();

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

	public function getWorldDirection(target:Matrix4):Matrix4 {

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

		return new Camera().copy(this);

	}

}