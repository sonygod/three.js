import three.Color;
import three.passes.Pass;

class RenderPass extends Pass {
	public var scene:three.Scene;
	public var camera:three.Camera;
	public var overrideMaterial:three.Material;
	public var clearColor:Color;
	public var clearAlpha:Float;
	public var clear:Bool;
	public var clearDepth:Bool;
	public var needsSwap:Bool;
	private var _oldClearColor:Color;

	public function new(scene:three.Scene, camera:three.Camera, overrideMaterial:three.Material = null, clearColor:Color = null, clearAlpha:Float = null) {
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

	public function render(renderer:three.Renderer, writeBuffer:three.WebGLRenderTarget, readBuffer:three.WebGLRenderTarget) {
		var oldAutoClear = renderer.autoClear;
		renderer.autoClear = false;

		var oldClearAlpha:Float;
		var oldOverrideMaterial:three.Material;

		if (this.overrideMaterial != null) {
			oldOverrideMaterial = this.scene.overrideMaterial;
			this.scene.overrideMaterial = this.overrideMaterial;
		}

		if (this.clearColor != null) {
			renderer.getClearColor(this._oldClearColor);
			renderer.setClearColor(this.clearColor);
		}

		if (this.clearAlpha != null) {
			oldClearAlpha = renderer.getClearAlpha();
			renderer.setClearAlpha(this.clearAlpha);
		}

		if (this.clearDepth == true) {
			renderer.clearDepth();
		}

		renderer.setRenderTarget(this.renderToScreen ? null : readBuffer);

		if (this.clear == true) {
			// TODO: Avoid using autoClear properties, see https://github.com/mrdoob/three.js/pull/15571#issuecomment-465669600
			renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
		}

		renderer.render(this.scene, this.camera);

		// restore
		if (this.clearColor != null) {
			renderer.setClearColor(this._oldClearColor);
		}

		if (this.clearAlpha != null) {
			renderer.setClearAlpha(oldClearAlpha);
		}

		if (this.overrideMaterial != null) {
			this.scene.overrideMaterial = oldOverrideMaterial;
		}

		renderer.autoClear = oldAutoClear;
	}
}