class WebGLAnimation {
    private var context:Dynamic = null;
    private var isAnimating:Bool = false;
    private var animationLoop:Dynamic = null;
    private var requestId:Int = null;

    private function onAnimationFrame(time:Float, frame:Dynamic) {
        animationLoop(time, frame);
        requestId = context.requestAnimationFrame(onAnimationFrame);
    }

    public function new() {
        this.start = function () {
            if (isAnimating) return;
            if (animationLoop == null) return;

            requestId = context.requestAnimationFrame(onAnimationFrame);
            isAnimating = true;
        }

        this.stop = function () {
            if (requestId != null) {
                context.cancelAnimationFrame(requestId);
                requestId = null;
            }

            isAnimating = false;
        }

        this.setAnimationLoop = function (callback:Dynamic) {
            animationLoop = callback;
        }

        this.setContext = function (value:Dynamic) {
            context = value;
        }
    }
}