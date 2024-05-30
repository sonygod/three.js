import three.StereoCamera;
import three.Vector2;

class StereoEffect {

    private var _stereo:StereoCamera;
    private var size:Vector2;

    public function new(renderer:Renderer) {
        _stereo = new StereoCamera();
        _stereo.aspect = 0.5;
        size = new Vector2();

        var setEyeSeparation = function(eyeSep:Float) {
            _stereo.eyeSep = eyeSep;
        }

        var setSize = function(width:Int, height:Int) {
            renderer.setSize(width, height);
        }

        var render = function(scene:Scene, camera:Camera) {
            if (scene.matrixWorldAutoUpdate == true) scene.updateMatrixWorld();

            if (camera.parent == null && camera.matrixWorldAutoUpdate == true) camera.updateMatrixWorld();

            _stereo.update(camera);

            renderer.getSize(size);

            if (renderer.autoClear) renderer.clear();
            renderer.setScissorTest(true);

            renderer.setScissor(0, 0, size.width / 2, size.height);
            renderer.setViewport(0, 0, size.width / 2, size.height);
            renderer.render(scene, _stereo.cameraL);

            renderer.setScissor(size.width / 2, 0, size.width / 2, size.height);
            renderer.setViewport(size.width / 2, 0, size.width / 2, size.height);
            renderer.render(scene, _stereo.cameraR);

            renderer.setScissorTest(false);
        }
    }
}