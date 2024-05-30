class Animation {
	var nodes:Nodes;
	var info:Info;
	var animationLoop:AnimationLoop;
	var requestId:Int;

	public function new(nodes:Nodes, info:Info) {
		this.nodes = nodes;
		this.info = info;
		this._init();
	}

	private function _init():Void {
		var update:Update = function(time:Float, frame:Int) {
			requestId = self.requestAnimationFrame(update);

			if (info.autoReset) info.reset();

			nodes.nodeFrame.update();
			info.frame = nodes.nodeFrame.frameId;

			if (animationLoop != null) animationLoop(time, frame);
		};

		update(0, 0);
	}

	public function dispose():Void {
		self.cancelAnimationFrame(requestId);
		requestId = null;
	}

	public function setAnimationLoop(callback:AnimationLoop):Void {
		animationLoop = callback;
	}
}

typedef AnimationLoop = Function<Float, Int -> Void>;

class Nodes {
	public var nodeFrame:NodeFrame;
}

class NodeFrame {
	public var frameId:Int;

	public function update():Void {
		// ...
	}
}

class Info {
	public var autoReset:Bool;
	public var frame:Int;

	public function reset():Void {
		// ...
	}
}