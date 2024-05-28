package three.lights;

import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.cameras.PerspectiveCamera;
import three.lights.LightShadow;

class PointLightShadow extends LightShadow {
    var _projScreenMatrix:Matrix4;
    var _lightPositionWorld:Vector3;
    var _lookTarget:Vector3;
    var _frameExtents:Vector2;
    var _viewportCount:Int;
    var _viewports:Array<Vector4>;
    var _cubeDirections:Array<Vector3>;
    var _cubeUps:Array<Vector3>;

    public function new() {
        super(new PerspectiveCamera(90, 1, 0.5, 500));
        this.isPointLightShadow = true;
        _frameExtents = new Vector2(4, 2);
        _viewportCount = 6;
        _viewports = [
            new Vector4(2, 1, 1, 1), // positive X
            new Vector4(0, 1, 1, 1), // negative X
            new Vector4(3, 1, 1, 1), // positive Z
            new Vector4(1, 1, 1, 1), // negative Z
            new Vector4(3, 0, 1, 1), // positive Y
            new Vector4(1, 0, 1, 1) // negative Y
        ];
        _cubeDirections = [
            new Vector3(1, 0, 0), new Vector3(-1, 0, 0), new Vector3(0, 0, 1),
            new Vector3(0, 0, -1), new Vector3(0, 1, 0), new Vector3(0, -1, 0)
        ];
        _cubeUps = [
            new Vector3(0, 1, 0), new Vector3(0, 1, 0), new Vector3(0, 1, 0),
            new Vector3(0, 1, 0), new Vector3(0, 0, 1), new Vector3(0, 0, -1)
        ];
        _projScreenMatrix = new Matrix4();
        _lightPositionWorld = new Vector3();
        _lookTarget = new Vector3();
    }

    public function updateMatrices(light:Any, viewportIndex:Int = 0):Void {
        var camera:PerspectiveCamera = cast this.camera;
        var shadowMatrix:Matrix4 = this.matrix;
        var far:Float = light.distance != null ? light.distance : camera.far;

        if (far != camera.far) {
            camera.far = far;
            camera.updateProjectionMatrix();
        }

        _lightPositionWorld.setFromMatrixPosition(light.matrixWorld);
        camera.position.copy(_lightPositionWorld);
        _lookTarget.copy(camera.position);
        _lookTarget.add(_cubeDirections[viewportIndex]);
        camera.up.copy(_cubeUps[viewportIndex]);
        camera.lookAt(_lookTarget);
        camera.updateMatrixWorld();

        shadowMatrix.makeTranslation(-_lightPositionWorld.x, -_lightPositionWorld.y, -_lightPositionWorld.z);

        _projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
        this._frustum.setFromProjectionMatrix(_projScreenMatrix);
    }
}