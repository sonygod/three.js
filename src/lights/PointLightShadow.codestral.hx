import three.lights.LightShadow;
import three.cameras.PerspectiveCamera;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;

class PointLightShadow extends LightShadow {

    private var _projScreenMatrix:Matrix4;
    private var _lightPositionWorld:Vector3;
    private var _lookTarget:Vector3;

    public function new() {
        super(new PerspectiveCamera(90, 1, 0.5, 500));

        this.isPointLightShadow = true;

        this._frameExtents = new Vector2(4, 2);

        this._viewportCount = 6;

        this._viewports = [
            new Vector4(2, 1, 1, 1),
            new Vector4(0, 1, 1, 1),
            new Vector4(3, 1, 1, 1),
            new Vector4(1, 1, 1, 1),
            new Vector4(3, 0, 1, 1),
            new Vector4(1, 0, 1, 1)
        ];

        this._cubeDirections = [
            new Vector3(1, 0, 0), new Vector3(-1, 0, 0), new Vector3(0, 0, 1),
            new Vector3(0, 0, -1), new Vector3(0, 1, 0), new Vector3(0, -1, 0)
        ];

        this._cubeUps = [
            new Vector3(0, 1, 0), new Vector3(0, 1, 0), new Vector3(0, 1, 0),
            new Vector3(0, 1, 0), new Vector3(0, 0, 1), new Vector3(0, 0, -1)
        ];

        this._projScreenMatrix = new Matrix4();
        this._lightPositionWorld = new Vector3();
        this._lookTarget = new Vector3();
    }

    public function updateMatrices(light:Dynamic, viewportIndex:Int = 0):Void {
        var camera = this.camera;
        var shadowMatrix = this.matrix;

        var far = Std.parseInt(Reflect.field(light, "distance")) ?? camera.far;

        if (far !== camera.far) {
            camera.far = far;
            camera.updateProjectionMatrix();
        }

        _lightPositionWorld.setFromMatrixPosition(Reflect.field(light, "matrixWorld"));
        camera.position.copy(_lightPositionWorld);

        _lookTarget.copy(camera.position);
        _lookTarget.add(this._cubeDirections[viewportIndex]);
        camera.up.copy(this._cubeUps[viewportIndex]);
        camera.lookAt(_lookTarget);
        camera.updateMatrixWorld();

        shadowMatrix.makeTranslation(- _lightPositionWorld.x, - _lightPositionWorld.y, - _lightPositionWorld.z);

        _projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
        this._frustum.setFromProjectionMatrix(_projScreenMatrix);
    }
}