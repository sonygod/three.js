package three.cameras;

import three.math.Matrix4;
import three.math.MathUtils;
import three.cameras.PerspectiveCamera;

class StereoCamera {
    public var type:String;
    public var aspect:Float;
    public var eyeSep:Float;
    public var cameraL:PerspectiveCamera;
    public var cameraR:PerspectiveCamera;
    private var _cache:Dynamic;
    private var _eyeRight:Matrix4;
    private var _eyeLeft:Matrix4;
    private var _projectionMatrix:Matrix4;

    public function new() {
        type = 'StereoCamera';
        aspect = 1;
        eyeSep = 0.064;
        cameraL = new PerspectiveCamera();
        cameraL.layers.enable(1);
        cameraL.matrixAutoUpdate = false;
        cameraR = new PerspectiveCamera();
        cameraR.layers.enable(2);
        cameraR.matrixAutoUpdate = false;
        _cache = {
            focus: null,
            fov: null,
            aspect: null,
            near: null,
            far: null,
            zoom: null,
            eyeSep: null
        };
        _eyeRight = new Matrix4();
        _eyeLeft = new Matrix4();
        _projectionMatrix = new Matrix4();
    }

    public function update(camera:PerspectiveCamera) {
        var cache = _cache;
        var needsUpdate = cache.focus != camera.focus || cache.fov != camera.fov ||
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
            _projectionMatrix.copyFrom(camera.projectionMatrix);
            var eyeSepHalf = eyeSep / 2;
            var eyeSepOnProjection = eyeSepHalf * cache.near / cache.focus;
            var ymax = (cache.near * Math.tan(MathUtils.degToRad(cache.fov * 0.5))) / cache.zoom;
            var xmin:Float, xmax:Float;
            // translate xOffset
            _eyeLeft.elements[12] = -eyeSepHalf;
            _eyeRight.elements[12] = eyeSepHalf;
            // for left eye
            xmin = -ymax * cache.aspect + eyeSepOnProjection;
            xmax = ymax * cache.aspect + eyeSepOnProjection;
            _projectionMatrix.elements[0] = 2 * cache.near / (xmax - xmin);
            _projectionMatrix.elements[8] = (xmax + xmin) / (xmax - xmin);
            cameraL.projectionMatrix.copyFrom(_projectionMatrix);
            // for right eye
            xmin = -ymax * cache.aspect - eyeSepOnProjection;
            xmax = ymax * cache.aspect - eyeSepOnProjection;
            _projectionMatrix.elements[0] = 2 * cache.near / (xmax - xmin);
            _projectionMatrix.elements[8] = (xmax + xmin) / (xmax - xmin);
            cameraR.projectionMatrix.copyFrom(_projectionMatrix);
        }
        cameraL.matrixWorld.copyFrom(camera.matrixWorld).multiply(_eyeLeft);
        cameraR.matrixWorld.copyFrom(camera.matrixWorld).multiply(_eyeRight);
    }
}