import three.StereoCamera;
import three.Vector2;

class StereoEffect {

	var _stereo:StereoCamera;
	var size:Vector2;

	public function new(renderer:Renderer) {
		_stereo = new StereoCamera();
		_stereo.aspect = 0.5;
		size = new Vector2();

		this.setEyeSeparation = function (eyeSep:Float) {
			_stereo.eyeSep = eyeSep;
		};

		this.setSize = function (width:Float, height:Float) {
			renderer.setSize(width, height);
		};

		this.render = function (scene:Scene, camera:Camera) {
			if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
			if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();
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
		};
	}
}