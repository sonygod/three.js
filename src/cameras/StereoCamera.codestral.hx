import js.Browser.console;
import js.Math;
import three.math.Matrix4;
import three.math.MathUtils;
import three.cameras.PerspectiveCamera;

class StereoCamera {

    public var type:String = 'StereoCamera';
    public var aspect:Float = 1.0;
    public var eyeSep:Float = 0.064;
    public var cameraL:PerspectiveCamera;
    public var cameraR:PerspectiveCamera;

    private var _cache:{
        focus:Float,
        fov:Float,
        aspect:Float,
        near:Float,
        far:Float,
        zoom:Float,
        eyeSep:Float
    };

    public function new() {
        this.cameraL = new PerspectiveCamera();
        this.cameraL.layers.enable(1);
        this.cameraL.matrixAutoUpdate = false;

        this.cameraR = new PerspectiveCamera();
        this.cameraR.layers.enable(2);
        this.cameraR.matrixAutoUpdate = false;

        this._cache = {
            focus:0.0,
            fov:0.0,
            aspect:0.0,
            near:0.0,
            far:0.0,
            zoom:0.0,
            eyeSep:0.0
        };
    }

    public function update(camera:PerspectiveCamera):Void {
        var cache = this._cache;
        var needsUpdate = cache.focus != camera.focus || cache.fov != camera.fov ||
            cache.aspect != camera.aspect * this.aspect || cache.near != camera.near ||
            cache.far != camera.far || cache.zoom != camera.zoom || cache.eyeSep != this.eyeSep;

        if (needsUpdate) {
            cache.focus = camera.focus;
            cache.fov = camera.fov;
            cache.aspect = camera.aspect * this.aspect;
            cache.near = camera.near;
            cache.far = camera.far;
            cache.zoom = camera.zoom;
            cache.eyeSep = this.eyeSep;

            var _projectionMatrix = new Matrix4();
            _projectionMatrix.copy(camera.projectionMatrix);
            var eyeSepHalf = cache.eyeSep / 2.0;
            var eyeSepOnProjection = eyeSepHalf * cache.near / cache.focus;
            var ymax = (cache.near * Math.tan(MathUtils.DEG2RAD * cache.fov * 0.5)) / cache.zoom;
            var xmin:Float;
            var xmax:Float;

            var _eyeLeft = new Matrix4();
            _eyeLeft.elements[12] = -eyeSepHalf;

            var _eyeRight = new Matrix4();
            _eyeRight.elements[12] = eyeSepHalf;

            xmin = - ymax * cache.aspect + eyeSepOnProjection;
            xmax = ymax * cache.aspect + eyeSepOnProjection;

            _projectionMatrix.elements[0] = 2 * cache.near / (xmax - xmin);
            _projectionMatrix.elements[8] = (xmax + xmin) / (xmax - xmin);

            this.cameraL.projectionMatrix.copy(_projectionMatrix);

            xmin = - ymax * cache.aspect - eyeSepOnProjection;
            xmax = ymax * cache.aspect - eyeSepOnProjection;

            _projectionMatrix.elements[0] = 2 * cache.near / (xmax - xmin);
            _projectionMatrix.elements[8] = (xmax + xmin) / (xmax - xmin);

            this.cameraR.projectionMatrix.copy(_projectionMatrix);
        }

        this.cameraL.matrixWorld.copy(camera.matrixWorld).multiply(_eyeLeft);
        this.cameraR.matrixWorld.copy(camera.matrixWorld).multiply(_eyeRight);
    }
}