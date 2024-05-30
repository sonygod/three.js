package three.renderers.webgl;

class WebGLAnimation {

    private var context:Dynamic = null;
    private var isAnimating:Bool = false;
    private var animationLoop:Dynamic = null;
    private var requestId:Dynamic = null;

    public function new() {}

    private function onAnimationFrame(time:Float, frame:Dynamic):Void {
        if (animationLoop != null) {
            animationLoop(time, frame);
        }

        requestId = context.requestAnimationFrame(onAnimationFrame);
    }

    public function start():Void {
        if (isAnimating || animationLoop == null) return;

        requestId = context.requestAnimationFrame(onAnimationFrame);
        isAnimating = true;
    }

    public function stop():Void {
        if (context != null && requestId != null) {
            context.cancelAnimationFrame(requestId);
            isAnimating = false;
        }
    }

    public function setAnimationLoop(callback:Dynamic):Void {
        animationLoop = callback;
    }

    public function setContext(value:Dynamic):Void {
        context = value;
    }
}