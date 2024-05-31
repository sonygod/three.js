import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Frustum;

class LightShadow {
    public var camera:Dynamic;
    public var bias:Float = 0;
    public var normalBias:Float = 0;
    public var radius:Float = 1;
    public var blurSamples:Int = 8;

    public var mapSize:Vector2 = new Vector2(512, 512);

    public var map:Dynamic = null;
    public var mapPass:Dynamic = null;
    public var matrix:Matrix4 = new Matrix4();

    public var autoUpdate:Bool = true;
    public var needsUpdate:Bool = false;

    private var _frustum:Frustum = new Frustum();
    private var _frameExtents:Vector2 = new Vector2(1, 1);

    private var _viewportCount:Int = 1;
    private var _viewports:Array<Vector4> = [new Vector4(0, 0, 1, 1)];

    private static var _projScreenMatrix:Matrix4 = new Matrix4();
    private static var _lightPositionWorld:Vector3 = new Vector3();
    private static var _lookTarget:Vector3 = new Vector3();

    public function new(camera:Dynamic) {
        this.camera = camera;
    }

    public function getViewportCount():Int {
        return _viewportCount;
    }

    public function getFrustum():Frustum {
        return _frustum;
    }

    public function updateMatrices(light:Dynamic):Void {
        var shadowCamera = camera;
        var shadowMatrix = matrix;

        _lightPositionWorld.setFromMatrixPosition(light.matrixWorld);
        shadowCamera.position.copy(_lightPositionWorld);

        _lookTarget.setFromMatrixPosition(light.target.matrixWorld);
        shadowCamera.lookAt(_lookTarget);
        shadowCamera.updateMatrixWorld();

        _projScreenMatrix.multiplyMatrices(shadowCamera.projectionMatrix, shadowCamera.matrixWorldInverse);
        _frustum.setFromProjectionMatrix(_projScreenMatrix);

        shadowMatrix.set(
            0.5, 0.0, 0.0, 0.5,
            0.0, 0.5, 0.0, 0.5,
            0.0, 0.0, 0.5, 0.5,
            0.0, 0.0, 0.0, 1.0
        );

        shadowMatrix.multiply(_projScreenMatrix);
    }

    public function getViewport(viewportIndex:Int):Vector4 {
        return _viewports[viewportIndex];
    }

    public function getFrameExtents():Vector2 {
        return _frameExtents;
    }

    public function dispose():Void {
        if (map != null) {
            map.dispose();
        }

        if (mapPass != null) {
            mapPass.dispose();
        }
    }

    public function copy(source:LightShadow):LightShadow {
        this.camera = source.camera.clone();

        this.bias = source.bias;
        this.radius = source.radius;

        this.mapSize.copy(source.mapSize);

        return this;
    }

    public function clone():LightShadow {
        return new LightShadow(camera).copy(this);
    }

    public function toJSON():Dynamic {
        var object:Dynamic = {};

        if (bias != 0) object.bias = bias;
        if (normalBias != 0) object.normalBias = normalBias;
        if (radius != 1) object.radius = radius;
        if (mapSize.x != 512 || mapSize.y != 512) object.mapSize = mapSize.toArray();

        object.camera = camera.toJSON(false).object;
        Reflect.deleteField(object.camera, "matrix");

        return object;
    }
}