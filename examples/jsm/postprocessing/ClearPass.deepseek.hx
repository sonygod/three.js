import three.Color;
import three.jsm.postprocessing.Pass;

class ClearPass extends Pass {

	public function new(clearColor:Int, clearAlpha:Float) {
		super();

		this.needsSwap = false;

		this.clearColor = (clearColor != null) ? clearColor : 0x000000;
		this.clearAlpha = (clearAlpha != null) ? clearAlpha : 0;
		this._oldClearColor = new Color();
	}

	public function render(renderer:Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
		var oldClearAlpha:Float;

		if (this.clearColor) {
			this._oldClearColor = renderer.getClearColor();
			oldClearAlpha = renderer.getClearAlpha();

			renderer.setClearColor(this.clearColor, this.clearAlpha);
		}

		renderer.setRenderTarget(this.renderToScreen ? null : readBuffer);
		renderer.clear();

		if (this.clearColor) {
			renderer.setClearColor(this._oldClearColor, oldClearAlpha);
		}
	}
}