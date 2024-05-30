import three.math.Matrix4;
import three.math.MathUtils;
import three.cameras.PerspectiveCamera;

class StereoCamera {

    public var type:String;
    public var aspect:Float;
    public var eyeSep:Float;
    public var cameraL:PerspectiveCamera;
    public var cameraR:PerspectiveCamera;
    private var _cache:Dynamic<Dynamic<Null<Dynamic<Null<Float>>>>>;
    
    private static var _eyeRight:Matrix4 = new Matrix4();
    private static var _eyeLeft:Matrix4 = new Matrix4();
    private static var _projectionMatrix:Matrix4 = new Matrix4();

    public function new() {
        this.type = 'StereoCamera';
        this.aspect = 1;
        this.eyeSep = 0.064;

        this.cameraL = new PerspectiveCamera();
        this.cameraL.layers.enable(1);
        this.cameraL.matrixAutoUpdate = false;

        this.cameraR = new PerspectiveCamera();
        this.cameraR.layers.enable(2);
        this.cameraR.matrixAutoUpdate = false;

        this._cache = {
            focus: null,
            fov: null,
            aspect: null,
            near: null,
            far: null,
            zoom: null,
            eyeSep: null
        };
    }

    public function update(camera:Dynamic):Void {
        var cache = this._cache;
        var needsUpdate:Bool = cache.focus != camera.focus || cache.fov != camera.fov ||
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

            // Off-axis stereoscopic effect based on
            // http://paulbourke.net/stereographics/stereorender/

            _projectionMatrix.copy(camera.projectionMatrix);
            var eyeSepHalf:Float = cache.eyeSep / 2;
            var eyeSepOnProjection:Float = eyeSepHalf * cache.near / cache.focus;
            var ymax:Float = (cache.near * Math.tan(MathUtils.DEG2RAD * cache.fov * 0.5)) / cache.zoom;
            var xmin:Float, xmax:Float;

            // translate xOffset

            _eyeLeft.elements[12] = -eyeSepHalf;
            _eyeRight.elements[12] = eyeSepHalf;

            // for left eye

            xmin = -ymax * cache.aspect + eyeSepOnProjection;
            xmax = ymax * cache.aspect + eyeSepOnProjection;

            _projectionMatrix.elements[0] = 2 * cache.near / (xmax - xmin);
            _projectionMatrix.elements[8] = (xmax + xmin) / (xmax - xmin);

            this.cameraL.projectionMatrix.copy(_projectionMatrix);

            // for right eye

            xmin = -ymax * cache.aspect - eyeSepOnProjection;
            xmax = ymax * cache.aspect - eyeSepOnProjection;

            _projectionMatrix.elements[0] = 2 * cache.near / (xmax - xmin);
            _projectionMatrix.elements[8] = (xmax + xmin) / (xmax - xmin);

            this.cameraR.projectionMatrix.copy(_projectionMatrix);
        }

        this.cameraL.matrixWorld.copy(camera.matrixWorld).multiply(_eyeLeft);
        this.cameraR.matrixWorld.copy(camera.matrixWorld).multiply(_eyeRight);
    }
}

@:expose("StereoCamera")
class StereoCameraExposer extends StereoCamera {}