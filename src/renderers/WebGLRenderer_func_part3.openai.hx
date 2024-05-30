package three.renderers;

import three.animation.WebGLAnimation;
import three.xr.XR;

class WebGLRenderer {
    private var onAnimationFrameCallback:Null<Void->Void>;
    private var animation:WebGLAnimation;
    private var xr:XR;

    public function new() {
        animation = new WebGLAnimation();
        animation.setAnimationLoop(onAnimationFrame);
    }

    private function onAnimationFrame(time:Float) {
        if (onAnimationFrameCallback != null) onAnimationFrameCallback(time);
    }

    private function onXRSessionStart() {
        animation.stop();
    }

    private function onXRSessionEnd() {
        animation.start();
    }

    public function setAnimationLoop(callback:Void->Void) {
        onAnimationFrameCallback = callback;
        xr.setAnimationLoop(callback);
        if (callback == null) animation.stop(); else animation.start();
    }

    public function render(scene:three.scenes.Scene, camera:three.cameras.Camera) {
        // ...
    }

    private function projectObject(object:three.objects.Object3D, camera:three.cameras.Camera, groupOrder:Int, sortObjects:Bool) {
        // ...
    }

    private function renderScene(currentRenderList:RenderList, scene:three.scenes.Scene, camera:three.cameras.Camera, viewport:three.math.Vector4) {
        // ...
    }

    private function renderTransmissionPass(opaqueObjects:Array<three.objects.Object3D>, transmissiveObjects:Array<three.objects.Object3D>, scene:three.scenes.Scene, camera:three.cameras.Camera) {
        // ...
    }

    private function renderObjects(renderList:Array<three.objects.Object3D>, scene:three.scenes.Scene, camera:three.cameras.Camera) {
        // ...
    }
}