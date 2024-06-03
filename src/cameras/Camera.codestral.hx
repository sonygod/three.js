import three.math.Matrix4;
import three.core.Object3D;
import three.constants.WebGLCoordinateSystem;

class Camera extends Object3D {

    public var isCamera:Bool;
    public var type:String;
    public var matrixWorldInverse:Matrix4;
    public var projectionMatrix:Matrix4;
    public var projectionMatrixInverse:Matrix4;
    public var coordinateSystem:String;

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

    public function getWorldDirection(target:Object3D):Object3D {
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
        return new this.constructor().copy(this);
    }
}