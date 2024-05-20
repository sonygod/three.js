class WebGLAnimation {

    var context:Null<js.html.Window>;
    var isAnimating:Bool = false;
    var animationLoop:Null<Dynamic->Void>;
    var requestId:Null<Int>;

    function onAnimationFrame(time:Float, frame:Int) {
        if (animationLoop != null) {
            animationLoop(time, frame);
        }
        requestId = context.requestAnimationFrame(onAnimationFrame);
    }

    public function new() {
    }

    public function start() {
        if (isAnimating || animationLoop == null) return;
        requestId = context.requestAnimationFrame(onAnimationFrame);
        isAnimating = true;
    }

    public function stop() {
        if (requestId != null) {
            context.cancelAnimationFrame(requestId);
        }
        isAnimating = false;
    }

    public function setAnimationLoop(callback:Dynamic->Void) {
        animationLoop = callback;
    }

    public function setContext(value:js.html.Window) {
        context = value;
    }
}