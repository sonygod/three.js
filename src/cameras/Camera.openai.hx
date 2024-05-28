package three.js.src.cameras;

import three.constants.GLCoordinateSystem;
import three.math.Matrix4;
import three.core.Object3D;

class Camera extends Object3D {

    public var isCamera:Bool = true;

    public var type:String = 'Camera';

    public var matrixWorldInverse:Matrix4;
    public var projectionMatrix:Matrix4;
    public var projectionMatrixInverse:Matrix4;
    public var coordinateSystem:GLCoordinateSystem;

    public function new() {
        super();
        matrixWorldInverse = new Matrix4();
        projectionMatrix = new Matrix4();
        projectionMatrixInverse = new Matrix4();
        coordinateSystem = GLCoordinateSystem;
    }

    public function copy(source:Camera, recursive:Bool):Camera {
        super.copy(source, recursive);
        matrixWorldInverse.copy(source.matrixWorldInverse);
        projectionMatrix.copy(source.projectionMatrix);
        projectionMatrixInverse.copy(source.projectionMatrixInverse);
        coordinateSystem = source.coordinateSystem;
        return this;
    }

    public function getWorldDirection(target:Vector3):Vector3 {
        return super.getWorldDirection(target).negate();
    }

    public function updateMatrixWorld(force:Bool):Void {
        super.updateMatrixWorld(force);
        matrixWorldInverse.copy(matrixWorld).invert();
    }

    public function updateWorldMatrix(updateParents:Bool, updateChildren:Bool):Void {
        super.updateWorldMatrix(updateParents, updateChildren);
        matrixWorldInverse.copy(matrixWorld).invert();
    }

    public function clone():Camera {
        return new Camera().copy(this);
    }
}