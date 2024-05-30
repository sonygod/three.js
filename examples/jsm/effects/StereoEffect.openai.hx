package three.js.effects;

import three.StereoCamera;
import three.Vector2;

class StereoEffect {
  private var _stereo:StereoCamera;
  private var size:Vector2;
  private var renderer:three.Renderer;

  public function new(renderer:three.Renderer) {
    _stereo = new StereoCamera();
    _stereo.aspect = 0.5;
    size = new Vector2();

    setEyeSeparation = function(eyeSep:Float) {
      _stereo.eyeSep = eyeSep;
    };

    setSize = function(width:Int, height:Int) {
      renderer.setSize(width, height);
    };

    render = function(scene:three.Scene, camera:three.Camera) {
      if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
      if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

      _stereo.update(camera);

      renderer.getSize(size);

      if (renderer.autoClear) renderer.clear();
      renderer.setScissorTest(true);

      renderer.setScissor(0, 0, Std.int(size.width / 2), Std.int(size.height));
      renderer.setViewport(0, 0, Std.int(size.width / 2), Std.int(size.height));
      renderer.render(scene, _stereo.cameraL);

      renderer.setScissor(Std.int(size.width / 2), 0, Std.int(size.width / 2), Std.int(size.height));
      renderer.setViewport(Std.int(size.width / 2), 0, Std.int(size.width / 2), Std.int(size.height));
      renderer.render(scene, _stereo.cameraR);

      renderer.setScissorTest(false);
    };
  }
}