import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class PointLightShadow extends LightShadow {
    public var _frameExtents:Vector2;
    public var _viewportCount:Int;
    public var _viewports:Array<Vector4>;
    public var _cubeDirections:Array<Vector3D>;
    public var _cubeUps:Array<Vector3D>;
    public var isPointLightShadow:Bool;

    public function new() {
        super(new PerspectiveCamera(90, 1, 0.5, 500));
        isPointLightShadow = true;
        _frameExtents = new Vector2(4, 2);
        _viewportCount = 6;
        _viewports = [
            new Vector4(2, 1, 1, 1),
            new Vector4(0, 1, 1, 1),
            new Vector4(3, 1, 1, 1),
            new Vector4(1, 1, 1, 1),
            new Vector4(3, 0, 1, 1),
            new Vector4(1, 0, 1, 1)
        ];
        _cubeDirections = [
            new Vector3D(1, 0, 0), new Vector3D(-1, 0, 0), new Vector3D(0, 0, 1),
            new Vector3D(0, 0, -1), new Vector3D(0, 1, 0), new Vector3D(0, -1, 0)
        ];
        _cubeUps = [
            new Vector3D(0, 1, 0), new Vector3D(0, 1, 0), new Vector3D(0, 1, 0),
            new Vector3D(0, 1, 0), new Vector3D(0, 0, 1), new Vector3D(0, 0, -1)
        ];
    }

    public function updateMatrices(light:Dynamic, viewportIndex:Int = 0) {
        var camera = this.camera;
        var shadowMatrix = this.matrix;
        var far = light.distance != null ? light.distance : camera.far;

        if (far != camera.far) {
            camera.far = far;
            camera.updateProjectionMatrix();
        }

        var _lightPositionWorld = new Vector3D();
        _lightPositionWorld.copyFromMatrixPosition(light.matrixWorld);
        camera.position.copyFrom(_lightPositionWorld);

        var _lookTarget = new Vector3D();
        _lookTarget.copyFrom(camera.position);
        _lookTarget.add(this._cubeDirections[viewportIndex]);
        camera.up.copyFrom(this._cubeUps[viewportIndex]);
        camera.lookAt(_lookTarget);
        camera.updateMatrixWorld(false);

        shadowMatrix.makeTranslation(-_lightPositionWorld.x, -_lightPositionWorld.y, -_lightPositionWorld.z);

        var _projScreenMatrix = new Matrix3D();
        _projScreenMatrix.copyFrom(camera.projectionMatrix);
        _projScreenMatrix.multiply(camera.matrixWorldInverse);
        this._frustum.setFromProjectionMatrix(_projScreenMatrix);
    }
}