import js.Browser.document;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Frustum;

class LightShadow {
    private var _projScreenMatrix: Matrix4 = new Matrix4();
    private var _lightPositionWorld: Vector3 = new Vector3();
    private var _lookTarget: Vector3 = new Vector3();

    public var camera: Camera;
    public var bias: Float = 0;
    public var normalBias: Float = 0;
    public var radius: Float = 1;
    public var blurSamples: Int = 8;
    public var mapSize: Vector2 = new Vector2(512, 512);
    public var map: js.html.CanvasElement = null;
    public var mapPass: Dynamic = null;
    public var matrix: Matrix4 = new Matrix4();
    public var autoUpdate: Bool = true;
    public var needsUpdate: Bool = false;
    private var _frustum: Frustum = new Frustum();
    private var _frameExtents: Vector2 = new Vector2(1, 1);
    private var _viewportCount: Int = 1;
    private var _viewports: Array<Vector4> = [new Vector4(0, 0, 1, 1)];

    public function new(camera: Camera) {
        this.camera = camera;
    }

    public function getViewportCount(): Int {
        return this._viewportCount;
    }

    public function getFrustum(): Frustum {
        return this._frustum;
    }

    public function updateMatrices(light: Light): Void {
        var shadowCamera = this.camera;
        var shadowMatrix = this.matrix;

        _lightPositionWorld.setFromMatrixPosition(light.matrixWorld);
        shadowCamera.position.copy(_lightPositionWorld);

        _lookTarget.setFromMatrixPosition(light.target.matrixWorld);
        shadowCamera.lookAt(_lookTarget);
        shadowCamera.updateMatrixWorld();

        _projScreenMatrix.multiplyMatrices(shadowCamera.projectionMatrix, shadowCamera.matrixWorldInverse);
        this._frustum.setFromProjectionMatrix(_projScreenMatrix);

        shadowMatrix.set(
            0.5, 0.0, 0.0, 0.5,
            0.0, 0.5, 0.0, 0.5,
            0.0, 0.0, 0.5, 0.5,
            0.0, 0.0, 0.0, 1.0
        );

        shadowMatrix.multiply(_projScreenMatrix);
    }

    public function getViewport(viewportIndex: Int): Vector4 {
        return this._viewports[viewportIndex];
    }

    public function getFrameExtents(): Vector2 {
        return this._frameExtents;
    }

    public function dispose(): Void {
        if (this.map != null) {
            document.body.removeChild(this.map);
        }

        if (this.mapPass != null) {
            this.mapPass.dispose();
        }
    }

    public function copy(source: LightShadow): LightShadow {
        this.camera = source.camera.clone();
        this.bias = source.bias;
        this.radius = source.radius;
        this.mapSize.copy(source.mapSize);

        return this;
    }

    public function clone(): LightShadow {
        return new LightShadow(this.camera).copy(this);
    }

    public function toJSON(): Dynamic {
        var object: Dynamic = {};

        if (this.bias != 0) object.bias = this.bias;
        if (this.normalBias != 0) object.normalBias = this.normalBias;
        if (this.radius != 1) object.radius = this.radius;
        if (this.mapSize.x != 512 || this.mapSize.y != 512) object.mapSize = this.mapSize.toArray();

        object.camera = this.camera.toJSON(false).object;
        Reflect.deleteField(object.camera, "matrix");

        return object;
    }
}