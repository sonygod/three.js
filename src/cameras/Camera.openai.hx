package cameras;

import constants.WebGLCoordinateSystem;
import math.Matrix4;
import core.Object3D;

class Camera extends Object3D {
    public var matrixWorldInverse:Matrix4;
    public var projectionMatrix:Matrix4;
    public var projectionMatrixInverse:Matrix4;
    public var coordinateSystem:WebGLCoordinateSystem;

    public function new() {
        super();
        
        this.isCamera = true;
        this.type = "Camera";
        
        matrixWorldInverse = new Matrix4();
        projectionMatrix = new Matrix4();
        projectionMatrixInverse = new Matrix4();
        
        coordinateSystem = WebGLCoordinateSystem;
    }
    
    public override function copy(source:Object, recursive:Bool):Object {
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
    
    public override function updateMatrixWorld(force:Bool):Void {
        super.updateMatrixWorld(force);
        matrixWorldInverse.copy(matrixWorld).invert();
    }
    
    public override function updateWorldMatrix(updateParents:Bool, updateChildren:Bool):Void {
        super.updateWorldMatrix(updateParents, updateChildren);
        matrixWorldInverse.copy(matrixWorld).invert();
    }
    
    public function clone():Camera {
        return new Camera().copy(this);
    }
}