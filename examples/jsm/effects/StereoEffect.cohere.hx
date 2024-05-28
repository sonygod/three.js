import js.three.StereoCamera;
import js.three.Vector2;

class StereoEffect {
    var _stereo: StereoCamera;
    var size: Vector2;

    public function new(renderer: dynamic) {
        _stereo = new StereoCamera();
        _stereo.aspect = 0.5;
        size = new Vector2();

        public function setEyeSeparation(eyeSep: Float) {
            _stereo.eyeSep = eyeSep;
        }

        public function setSize(width: Int, height: Int) {
            renderer.setSize(width, height);
        }

        public function render(scene: dynamic, camera: dynamic) {
            if (scene.matrixWorldAutoUpdate)
                scene.updateMatrixWorld();

            if (camera.parent == null && camera.matrixWorldAutoUpdate)
                camera.updateMatrixWorld();

            _stereo.update(camera);

            size = renderer.getSize();

            if (renderer.autoClear)
                renderer.clear();

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

class Export {
    static public var StereoEffect = StereoEffect;
}