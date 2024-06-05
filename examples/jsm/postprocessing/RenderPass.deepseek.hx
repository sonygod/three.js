import three.Color;
import jsm.postprocessing.Pass;

class RenderPass extends Pass {

	public function new(scene:Scene, camera:Camera, overrideMaterial:Material = null, clearColor:Color = null, clearAlpha:Float = null) {
		super();

		this.scene = scene;
		this.camera = camera;

		this.overrideMaterial = overrideMaterial;

		this.clearColor = clearColor;
		this.clearAlpha = clearAlpha;

		this.clear = true;
		this.clearDepth = false;
		this.needsSwap = false;
		this._oldClearColor = new Color();
	}

	public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
		var oldAutoClear = renderer.autoClear;
		renderer.autoClear = false;

		var oldClearAlpha:Float, oldOverrideMaterial:Material;

		if (this.overrideMaterial !== null) {
			oldOverrideMaterial = this.scene.overrideMaterial;
			this.scene.overrideMaterial = this.overrideMaterial;
		}

		if (this.clearColor !== null) {
			renderer.getClearColor(this._oldClearColor);
			renderer.setClearColor(this.clearColor);
		}

		if (this.clearAlpha !== null) {
			oldClearAlpha = renderer.getClearAlpha();
			renderer.setClearAlpha(this.clearAlpha);
		}

		if (this.clearDepth == true) {
			renderer.clearDepth();
		}

		renderer.setRenderTarget(this.renderToScreen ? null : readBuffer);

		if (this.clear == true) {
			renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
		}

		renderer.render(this.scene, this.camera);

		if (this.clearColor !== null) {
			renderer.setClearColor(this._oldClearColor);
		}

		if (this.clearAlpha !== null) {
			renderer.setClearAlpha(oldClearAlpha);
		}

		if (this.overrideMaterial !== null) {
			this.scene.overrideMaterial = oldOverrideMaterial;
		}

		renderer.autoClear = oldAutoClear;
	}
}