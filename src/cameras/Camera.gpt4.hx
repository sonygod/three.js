import three.constants.WebGLCoordinateSystem;
import three.math.Matrix4;
import three.core.Object3D;

class Camera extends Object3D {

    public var isCamera:Bool;
    public var matrixWorldInverse:Matrix4;
    public var projectionMatrix:Matrix4;
    public var projectionMatrixInverse:Matrix4;
    public var coordinateSystem:WebGLCoordinateSystem;

    public function new() {
        super();

        this.isCamera = true;

        this.type = 'Camera';

        this.matrixWorldInverse = new Matrix4();

        this.projectionMatrix = new Matrix4();
        this.projectionMatrixInverse = new Matrix4();

        this.coordinateSystem = WebGLCoordinateSystem;
    }

    public function copy(source:Camera, ?recursive:Bool):Camera {
        super.copy(source, recursive);

        this.matrixWorldInverse.copy(source.matrixWorldInverse);

        this.projectionMatrix.copy(source.projectionMatrix);
        this.projectionMatrixInverse.copy(source.projectionMatrixInverse);

        this.coordinateSystem = source.coordinateSystem;

        return this;
    }

    public function getWorldDirection(target:Vector3):Vector3 {
        return super.getWorldDirection(target).negate();
    }

    public function updateMatrixWorld(?force:Bool):Void {
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