package three.cameras;

import three.math.Matrix4;
import three.math.MathUtils;
import three.cameras.PerspectiveCamera;

class StereoCamera {
    public var type:String = 'StereoCamera';
    public var aspect:Float = 1;
    public var eyeSep:Float = 0.064;
    public var cameraL:PerspectiveCamera;
    public var cameraR:PerspectiveCamera;
    private var _cache:Dynamic = { focus:null, fov:null, aspect:null, near:null, far:null, zoom:null, eyeSep:null };
    private var _eyeRight:Matrix4 = new Matrix4();
    private var _eyeLeft:Matrix4 = new Matrix4();
    private var _projectionMatrix:Matrix4 = new Matrix4();

    public function new() {
        cameraL = new PerspectiveCamera();
        cameraL.layers.enable(1);
        cameraL.matrixAutoUpdate = false;

        cameraR = new PerspectiveCamera();
        cameraR.layers.enable(2);
        cameraR.matrixAutoUpdate = false;
    }

    public function update(camera:Camera) {
        var cache:_Cache = _cache;
        var needsUpdate:Bool = cache.focus != camera.focus || cache.fov != camera.fov ||
            cache.aspect != camera.aspect * aspect || cache.near != camera.near ||
            cache.far != camera.far || cache.zoom != camera.zoom || cache.eyeSep != eyeSep;

        if (needsUpdate) {
            cache.focus = camera.focus;
            cache.fov = camera.fov;
            cache.aspect = camera.aspect * aspect;
            cache.near = camera.near;
            cache.far = camera.far;
            cache.zoom = camera.zoom;
            cache.eyeSep = eyeSep;

            // Off-axis stereoscopic effect based on
            // http://paulbourke.net/stereographics/stereorender/

            _projectionMatrix.copyFromMatrix(camera.projectionMatrix);
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

            cameraL.projectionMatrix.copyFromMatrix(_projectionMatrix);

            // for right eye

            xmin = -ymax * cache.aspect - eyeSepOnProjection;
            xmax = ymax * cache.aspect - eyeSepOnProjection;

            _projectionMatrix.elements[0] = 2 * cache.near / (xmax - xmin);
            _projectionMatrix.elements[8] = (xmax + xmin) / (xmax - xmin);

            cameraR.projectionMatrix.copyFromMatrix(_projectionMatrix);
        }

        cameraL.matrixWorld.multiplyMatrices(camera.matrixWorld, _eyeLeft);
        cameraR.matrixWorld.multiplyMatrices(camera.matrixWorld, _eyeRight);
    }
}