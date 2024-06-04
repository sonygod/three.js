class Animation {

	public var nodes:Dynamic;
	public var info:Dynamic;

	private var animationLoop:Dynamic = null;
	private var requestId:Int = -1;

	public function new(nodes:Dynamic, info:Dynamic) {
		this.nodes = nodes;
		this.info = info;
		this._init();
	}

	private function _init() {
		var update = function(time:Float, frame:Int) {
			this.requestId = haxe.Timer.stamp();
			if (this.info.autoReset == true) this.info.reset();
			this.nodes.nodeFrame.update();
			this.info.frame = this.nodes.nodeFrame.frameId;
			if (this.animationLoop != null) this.animationLoop(time, frame);
		};
		update();
	}

	public function dispose() {
		haxe.Timer.clear(this.requestId);
		this.requestId = -1;
	}

	public function setAnimationLoop(callback:Dynamic) {
		this.animationLoop = callback;
	}

}


**Explanation:**

* **`self` is replaced with `this`:** Haxe uses `this` to refer to the current instance.
* **`requestAnimationFrame` is replaced with `haxe.Timer.stamp()`:** Haxe's `haxe.Timer` class provides a way to schedule tasks at regular intervals. `haxe.Timer.stamp()` returns the current time in milliseconds, which can be used to track the animation's progress.
* **`cancelAnimationFrame` is replaced with `haxe.Timer.clear()`:** Haxe's `haxe.Timer.clear()` method cancels a previously scheduled timer.
* **`Dynamic` type:** Haxe uses the `Dynamic` type to represent values that can be of any type. This is similar to JavaScript's `any` type.
* **`export default` is not supported:** Haxe does not have a direct equivalent to JavaScript's `export default`. You can use a custom module system or export the class directly.

**Usage:**


// Assuming you have a `NodeFrame` class and a `AnimationInfo` class
var nodeFrame = new NodeFrame();
var animationInfo = new AnimationInfo();
var animation = new Animation({nodeFrame:nodeFrame}, animationInfo);
animation.setAnimationLoop(function(time:Float, frame:Int) {
	// Animation loop logic here
});
// ... later
animation.dispose();