import LightShadow.LightShadow;
import PerspectiveCamera.PerspectiveCamera;
import Matrix4.Matrix4;
import Vector2.Vector2;
import Vector3.Vector3;
import Vector4.Vector4;

class PointLightShadow extends LightShadow {
    static var _projScreenMatrix:Matrix4 = Matrix4.identity();
    static var _lightPositionWorld:Vector3 = Vector3.zero();
    static var _lookTarget:Vector3 = Vector3.zero();

    public function new() {
        super(new PerspectiveCamera(90, 1, 0.5, 500));

        this.isPointLightShadow = true;

        this._frameExtents = new Vector2(4, 2);

        this._viewportCount = 6;

        this._viewports = [
            // These viewports map a cube-map onto a 2D texture with the
            // following orientation:
            //
            //  xzXZ
            //   y Y
            //
            // X - Positive x direction
            // x - Negative x direction
            // Y - Positive y direction
            // y - Negative y direction
            // Z - Positive z direction
            // z - Negative z direction

            // positive X
            new Vector4(2, 1, 1, 1),
            // negative X
            new Vector4(0, 1, 1, 1),
            // positive Z
            new Vector4(3, 1, 1, 1),
            // negative Z
            new Vector4(1, 1, 1, 1),
            // positive Y
            new Vector4(3, 0, 1, 1),
            // negative Y
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

    public function updateMatrices(light:Vector3, viewportIndex:Int = 0) {
        var camera:PerspectiveCamera = this.camera;
        var shadowMatrix:Matrix4 = this.matrix;

        var far:Float = light.distance || camera.far;

        if (far !== camera.far) {
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