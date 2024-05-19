import haxe.ds.StringMap;
import three.math.Matrix4;
import three.math.MathUtils;
import three.cameras.PerspectiveCamera;

class StereoCamera {

    public var type:String;
    public var aspect:Float;
    public var eyeSep:Float;
    public var cameraL:PerspectiveCamera;
    public var cameraR:PerspectiveCamera;
    private var _cache:StringMap<Float>;
    private var _eyeRight:Matrix4;
    private var _eyeLeft:Matrix4;
    private var _projectionMatrix:Matrix4;

    public function new() {
        this.type = "StereoCamera";
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
        this._eyeRight = new Matrix4();
        this._eyeLeft = new Matrix4();
        this._projectionMatrix = new Matrix4();
    }

    public function update(camera:PerspectiveCamera):Void {
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

            this._projectionMatrix.copy(camera.projectionMatrix);
            var eyeSepHalf:Float = cache.eyeSep / 2;
            var eyeSepOnProjection:Float = eyeSepHalf * cache.near / cache.focus;
            var ymax:Float = (cache.near * Math.tan(MathUtils.DEG2RAD * cache.fov * 0.5)) / cache.zoom;
            var xmin:Float, xmax:Float;

            // translate xOffset

            this._eyeLeft.setElement(12, -eyeSepHalf);
            this._eyeRight.setElement(12, eyeSepHalf);

            // for left eye

            xmin = -ymax * cache.aspect + eyeSepOnProjection;
            xmax = ymax * cache.aspect + eyeSepOnProjection;

            this._projectionMatrix.setElement(0, 2 * cache.near / (xmax - xmin));
            this._projectionMatrix.setElement(8, (xmax + xmin) / (xmax - xmin));

            this.cameraL.projectionMatrix.copy(this._projectionMatrix);

            // for right eye

            xmin = -ymax * cache.aspect - eyeSepOnProjection;
            xmax = ymax * cache.aspect - eyeSepOnProjection;

            this._projectionMatrix.setElement(0, 2 * cache.near / (xmax - xmin));
            this._projectionMatrix.setElement(8, (xmax + xmin) / (xmax - xmin));

            this.cameraR.projectionMatrix.copy(this._projectionMatrix);

        }

        this.cameraL.matrixWorld.copy(camera.matrixWorld).multiply(this._eyeLeft);
        this.cameraR.matrixWorld.copy(camera.matrixWorld).multiply(this._eyeRight);

    }

}

typedef StringMap<Float> Cache;

typedef Nature(haxe.extern.EitherType<Matrix4,Null>)->Matrix4 Corsession;

typedef Nature(haxe.extern.EitherType<PerspectiveCamera,Null>)->PerspectiveCamera Callibrated;

inline static function  new_Cache(): Cache {return {focus: null,fov: null,aspect: null,near: null,far: null,zoom: null,eyeSep: null};}

```
注意：Haxe 不支持 `const` ，要使用 `typedef` 和 `inline static function` 进行代替。