import haxe.ds.StringMap;

class StereoCamera {
    public var aspect:Float = 1;
    public var eyeSep:Float;
    public var cameraL:PerspectiveCamera;
    public var cameraR:PerspectiveCamera;
    private var _cache:StringMap<Dynamic>;

    public function new() {
        eyeSep = 0.064;
        cameraL = PerspectiveCamera._new();
        cameraL.layers.enable(1);
        cameraL.matrixAutoUpdate = false;
        cameraR = PerspectiveCamera._new();
        cameraR.layers.enable(2);
        cameraR.matrixAutoUpdate = false;
        _cache = StringMap<Dynamic>._new();
    }

    public function update(camera:PerspectiveCamera):Void {
        var cache = _cache;
        var needsUpdate = cache.exists('focus') && cache.get('focus') != camera.focus ||
            cache.exists('fov') && cache.get('fov') != camera.fov ||
            cache.exists('aspect') && cache.get('aspect') != camera.aspect * aspect ||
            cache.exists('near') && cache.get('near') != camera.near ||
            cache.exists('far') && cache.get('far') != camera.far ||
            cache.exists('zoom') && cache.get('zoom') != camera.zoom ||
            cache.exists('eyeSep') && cache.get('eyeSep') != eyeSep;

        if (needsUpdate) {
            cache.set('focus', camera.focus);
            cache.set('fov', camera.fov);
            cache.set('aspect', camera.aspect * aspect);
            cache.set('near', camera.near);
            cache.set('far', camera.far);
            cache.set('zoom', camera.zoom);
            cache.set('eyeSep', eyeSep);

            var eyeSepHalf:Float = eyeSep / 2;
            var eyeSepOnProjection:Float = eyeSepHalf * cache.get_Float('near') / cache.get_Float('focus');
            var ymax:Float = (cache.get_Float('near') * Math.tan(Math.PI * cache.get_Float('fov') / 360 * 0.5)) / cache.get_Float('zoom');
            var xmin:Float, xmax:Float;

            var _eyeLeft:Matrix4 = camera.projectionMatrix.clone();
            var _eyeRight:Matrix4 = camera.projectionMatrix.clone();

            _eyeLeft.elements[12] = -eyeSepHalf;
            _eyeRight.elements[12] = eyeSepHalf;

            xmin = -ymax * cache.get_Float('aspect') + eyeSepOnProjection;
            xmax = ymax * cache.get_Float('aspect') + eyeSepOnProjection;

            _eyeLeft.elements[0] = 2 * cache.get_Float('near') / (xmax - xmin);
            _eyeLeft.elements[8] = (xmax + xmin) / (xmax - xmin);

            cameraL.projectionMatrix = _eyeLeft;

            xmin = -ymax * cache.get_Float('aspect') - eyeSepOnProjection;
            xmax = ymax * cache.get_Float('aspect') - eyeSepOnProjection;

            _eyeRight.elements[0] = 2 * cache.get_Float('near') / (xmax - xmin);
            _eyeRight.elements[8] = (xmax + xmin) / (xmax - xmin);

            cameraR.projectionMatrix = _eyeRight;
        }

        cameraL.matrixWorld = camera.matrixWorld.clone().multiply(Matrix4._new(_eyeLeft.elements));
        cameraR.matrixWorld = camera.matrixWorld.clone().multiply(Matrix4._new(_eyeRight.elements));
    }
}