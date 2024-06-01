class WebGLAnimation {

	private var context:Dynamic = null;
	private var isAnimating:Bool = false;
	private var animationLoop:Dynamic = null;
	private var requestId:Dynamic = null;

	private function onAnimationFrame( time:Float, frame:Int ):Void {
		animationLoop(time, frame);
		requestId = context.requestAnimationFrame(onAnimationFrame);
	}

	public function start():Void {
		if (isAnimating) return;
		if (animationLoop == null) return;

		requestId = context.requestAnimationFrame(onAnimationFrame);
		isAnimating = true;
	}

	public function stop():Void {
		context.cancelAnimationFrame(requestId);
		isAnimating = false;
	}

	public function setAnimationLoop(callback:Dynamic):Void {
		animationLoop = callback;
	}

	public function setContext(value:Dynamic):Void {
		context = value;
	}

}