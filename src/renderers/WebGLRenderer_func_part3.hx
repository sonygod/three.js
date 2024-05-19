package three;

import three.animation.WebGLAnimation;
import three.xr.XR;

class WebGLRenderer {
  var onAnimationFrameCallback:Dynamic->Void;
  var animation:WebGLAnimation;
  var xr:XR;

  public function new() {
    animation = new WebGLAnimation();
    animation.setAnimationLoop(onAnimationFrame);

    if (untyped self != null) animation.setContext(untyped self);

    this.setAnimationLoop = function(callback:Dynamic->Void) {
      onAnimationFrameCallback = callback;
      xr.setAnimationLoop(callback);
      if (callback == null) animation.stop(); else animation.start();
    };

    xr.addEventListener("sessionstart", onXRSessionStart);
    xr.addEventListener("sessionend", onXRSessionEnd);
  }

  public function onXRSessionStart() {
    animation.stop();
  }

  public function onXRSessionEnd() {
    animation.start();
  }

  public function onAnimationFrame(time:Float) {
    if (onAnimationFrameCallback != null) onAnimationFrameCallback(time);
  }

  public function render(scene:Scene, camera:Camera) {
    if (camera == null || !Std.is(camera, Camera)) {
      console.error("THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.");
      return;
    }

    if (_isContextLost) return;

    // update scene graph
    if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();

    // update camera matrices and frustum
    if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

    if (xr.enabled && xr.isPresenting) {
      if (xr.cameraAutoUpdate) xr.updateCamera(camera);
      camera = xr.getCamera(); // use XR camera for rendering
    }

    // ...
  }

  // ...
}