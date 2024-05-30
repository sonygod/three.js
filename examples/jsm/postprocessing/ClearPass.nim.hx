import three.Color;
import three.examples.jsm.postprocessing.Pass;

class ClearPass extends Pass {

	public var needsSwap:Bool;
	public var clearColor:Int;
	public var clearAlpha:Float;
	private var _oldClearColor:Color;

	public function new(clearColor:Int = 0x000000, clearAlpha:Float = 0) {
		super();

		this.needsSwap = false;

		this.clearColor = clearColor;
		this.clearAlpha = clearAlpha;
		this._oldClearColor = new Color();
	}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic) {

		var oldClearAlpha:Float;

		if (this.clearColor != null) {

			renderer.getClearColor(this._oldClearColor);
			oldClearAlpha = renderer.getClearAlpha();

			renderer.setClearColor(this.clearColor, this.clearAlpha);

		}

		renderer.setRenderTarget(this.renderToScreen ? null : readBuffer);
		renderer.clear();

		if (this.clearColor != null) {

			renderer.setClearColor(this._oldClearColor, oldClearAlpha);

		}

	}

}