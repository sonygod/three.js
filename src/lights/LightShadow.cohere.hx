import Math.Matrix4;
import Math.Vector2;
import Math.Vector3;
import Math.Vector4;
import Math.Frustum;

class LightShadow {
    public var camera:Camera;
    public var bias:Float;
    public var normalBias:Float;
    public var radius:Float;
    public var blurSamples:Int;
    public var mapSize:Vector2;
    public var map:Dynamic;
    public var mapPass:Dynamic;
    public var matrix:Matrix4;
    public var autoUpdate:Bool;
    public var needsUpdate:Bool;
    private var _frustum:Frustum;
    private var _frameExtents:Vector2;
    private var _viewportCount:Int;
    private var _viewports:Array<Vector4>;

    public function new(camera:Camera) {
        this.camera = camera;
        this.bias = 0.0;
        this.normalBias = 0.0;
        this.radius = 1.0;
        this.blurSamples = 8;
        this.mapSize = new Vector2(512, 512);
        this.matrix = new Matrix4();
        this.autoUpdate = true;
        this.needsUpdate = false;
        this._frustum = new Frustum();
        this._frameExtents = new Vector2(1, 1);
        this._viewportCount = 1;
        this._viewports = [new Vector4(0, 0, 1, 1)];
    }

    public function getViewportCount():Int {
        return _viewportCount;
    }

    public function getFrustum():Frustum {
        return _frustum;
    }

    public function updateMatrices(light:Dynamic) {
        var shadowCamera = this.camera;
        var shadowMatrix = this.matrix;
        var _lightPositionWorld = new Vector3();
        _lightPositionWorld.setFromMatrixPosition(light.matrixWorld);
        shadowCamera.position.copy(_lightPositionWorld);
        var _lookTarget = new Vector3();
        _lookTarget.setFromMatrixPosition(light.target.matrixWorld);
        shadowCamera.lookAt(_lookTarget);
        shadowCamera.updateMatrixWorld();
        var _projScreenMatrix = new Matrix4();
        _projScreenMatrix.multiplyMatrices(shadowCamera.projectionMatrix, shadowCamera.matrixWorldInverse);
        this._frustum.setFromProjectionMatrix(_projScreenMatrix);
        shadowMatrix.set(0.5, 0.0, 0.0, 0.5, 0.0, 0.5, 0.0, 0.5, 0.0, 0.0, 0.5, 0.5, 0.0, 0.0, 0.0, 1.0);
        shadowMatrix.multiply(_projScreenMatrix);
    }

    public function getViewport(viewportIndex:Int):Vector4 {
        return _viewports[viewportIndex];
    }

    public function getFrameExtents():Vector2 {
        return _frameExtents;
    }

    public function dispose() {
        if (this.map != null) {
            this.map.dispose();
        }
        if (this.mapPass != null) {
            this.mapPass.dispose();
        }
    }

    public function copy(source:LightShadow):LightShadow {
        this.camera = source.camera.clone();
        this.bias = source.bias;
        this.radius = source.radius;
        this.mapSize = source.mapSize.clone();
        return this;
    }

    public function clone():LightShadow {
        return new LightShadow(null).copy(this);
    }

    public function toJSON():Dynamic {
        var object = new Hash<Dynamic>();
        if (this.bias != 0) object.bias = this.bias;
        if (this.normalBias != 0) object.normalBias = this.normalBias;
        if (this.radius != 1) object.radius = this.radius;
        if (this.mapSize.x != 512 || this.mapSize.y != 512) object.mapSize = this.mapSize.toArray();
        object.camera = this.camera.toJSON(false).object;
        delete object.camera.matrix;
        return object;
    }
}