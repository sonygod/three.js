class WebGLAnimation {

    private var context:Any = null;
    private var isAnimating:Bool = false;
    private var animationLoop:Dynamic = null;
    private var requestId:Int = null;

    public function new() {}

    private function onAnimationFrame(time:Float, frame:Int):Void {

        animationLoop(time, frame);
        requestId = js.Browser.requestAnimationFrame(onAnimationFrame);

    }

    public function start():Void {

        if (isAnimating) return;
        if (animationLoop == null) return;

        requestId = js.Browser.requestAnimationFrame(onAnimationFrame);
        isAnimating = true;

    }

    public function stop():Void {

        js.Browser.cancelAnimationFrame(requestId);
        isAnimating = false;

    }

    public function setAnimationLoop(callback:Dynamic):Void {

        animationLoop = callback;

    }

    public function setContext(value:Any):Void {

        context = value;

    }

}