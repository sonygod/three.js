class Animation {

	var nodes:Dynamic;
	var info:Dynamic;
	var animationLoop:Dynamic;
	var requestId:Int;

	public function new(nodes:Dynamic, info:Dynamic) {
		this.nodes = nodes;
		this.info = info;
		this.animationLoop = null;
		this.requestId = null;
		this._init();
	}

	private function _init() {
		var update = function(time:Float, frame:Int) {
			this.requestId = js.Browser.requestAnimationFrame(update);
			if (this.info.autoReset == true) this.info.reset();
			this.nodes.nodeFrame.update();
			this.info.frame = this.nodes.nodeFrame.frameId;
			if (this.animationLoop != null) this.animationLoop(time, frame);
		};
		update();
	}

	public function dispose() {
		js.Browser.cancelAnimationFrame(this.requestId);
		this.requestId = null;
	}

	public function setAnimationLoop(callback:Dynamic) {
		this.animationLoop = callback;
	}

}