import js.Browser.window;
import three.js.examples.jsm.postprocessing.Pass;

class MaskPass extends Pass {

	public function new(scene:Dynamic, camera:Dynamic) {
		super();

		this.scene = scene;
		this.camera = camera;

		this.clear = true;
		this.needsSwap = false;

		this.inverse = false;
	}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic) {

		var context = renderer.getContext();
		var state = renderer.state;

		state.buffers.color.setMask(false);
		state.buffers.depth.setMask(false);

		state.buffers.color.setLocked(true);
		state.buffers.depth.setLocked(true);

		var writeValue = if (this.inverse) 0 else 1;
		var clearValue = if (this.inverse) 1 else 0;

		state.buffers.stencil.setTest(true);
		state.buffers.stencil.setOp(context.REPLACE, context.REPLACE, context.REPLACE);
		state.buffers.stencil.setFunc(context.ALWAYS, writeValue, 0xffffffff);
		state.buffers.stencil.setClear(clearValue);
		state.buffers.stencil.setLocked(true);

		renderer.setRenderTarget(readBuffer);
		if (this.clear) renderer.clear();
		renderer.render(this.scene, this.camera);

		renderer.setRenderTarget(writeBuffer);
		if (this.clear) renderer.clear();
		renderer.render(this.scene, this.camera);

		state.buffers.color.setLocked(false);
		state.buffers.depth.setLocked(false);

		state.buffers.color.setMask(true);
		state.buffers.depth.setMask(true);

		state.buffers.stencil.setLocked(false);
		state.buffers.stencil.setFunc(context.EQUAL, 1, 0xffffffff);
		state.buffers.stencil.setOp(context.KEEP, context.KEEP, context.KEEP);
		state.buffers.stencil.setLocked(true);
	}
}

class ClearMaskPass extends Pass {

	public function new() {
		super();

		this.needsSwap = false;
	}

	public function render(renderer:Dynamic) {

		renderer.state.buffers.stencil.setLocked(false);
		renderer.state.buffers.stencil.setTest(false);
	}
}

typedef MaskPassPass = {
	var scene:Dynamic;
	var camera:Dynamic;
	var clear:Bool;
	var needsSwap:Bool;
	var inverse:Bool;

	function new(scene:Dynamic, camera:Dynamic):Void;
	function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic):Void;
}

typedef ClearMaskPassPass = {
	var needsSwap:Bool;

	function new():Void;
	function render(renderer:Dynamic):Void;
}

@:native("three.js.examples.jsm.postprocessing.MaskPass") class MaskPass extends MaskPassPass {}
@:native("three.js.examples.jsm.postprocessing.ClearMaskPass") class ClearMaskPass extends ClearMaskPassPass {}