import three.js.src.lights.LightShadow;
import three.js.src.cameras.PerspectiveCamera;
import three.js.src.math.Matrix4;
import three.js.src.math.Vector2;
import three.js.src.math.Vector3;
import three.js.src.math.Vector4;

class PointLightShadow extends LightShadow {

    static var _projScreenMatrix:Matrix4 = new Matrix4();
    static var _lightPositionWorld:Vector3 = new Vector3();
    static var _lookTarget:Vector3 = new Vector3();

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

    }

    public function updateMatrices(light:Dynamic, viewportIndex:Int = 0):Void {

        var camera:PerspectiveCamera = this.camera;
        var shadowMatrix:Matrix4 = this.matrix;

        var far:Float = if (light.distance != null) light.distance else camera.far;

        if (far != camera.far) {

            camera.far = far;
            camera.updateProjectionMatrix();

        }

        _lightPositionWorld.setFromMatrixPosition(light.matrixWorld);
        camera.position.copy(_lightPositionWorld);

        _lookTarget.copy(camera.position);
        _lookTarget.add(this._cubeDirections[viewportIndex]);
        camera.up.copy(this._cubeUps[viewportIndex]);
        camera.lookAt(_lookTarget);
        camera.updateMatrixWorld();

        shadowMatrix.makeTranslation(-_lightPositionWorld.x, -_lightPositionWorld.y, -_lightPositionWorld.z);

        _projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
        this._frustum.setFromProjectionMatrix(_projScreenMatrix);

    }

}