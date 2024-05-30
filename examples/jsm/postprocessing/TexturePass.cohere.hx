import js.three.ShaderMaterial;
import js.three.UniformsUtils;

import js.three.postprocessing.Pass;
import js.three.postprocessing.FullScreenQuad;
import js.three.shaders.CopyShader;

class TexturePass extends Pass {
	public var map:Dynamic;
	public var opacity:Float = 1.0;
	public var uniforms:Dynamic;
	public var material:ShaderMaterial;
	public var needsSwap:Bool;
	public var fsQuad:FullScreenQuad;

	public function new(map:Dynamic, ?opacity:Float) {
		super();
		var shader = CopyShader;
		this.map = map;
		this.opacity = (opacity != null) ? opacity : 1.0;
		this.uniforms = UniformsUtils.clone(shader.uniforms);
		this.material = ShaderMaterial({
			uniforms: this.uniforms,
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader,
			depthTest: false,
			depthWrite: false,
			premultipliedAlpha: true
		});
		this.needsSwap = false;
		this.fsQuad = FullScreenQuad(null);
	}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, deltaTime:Float, maskActive:Bool) {
		var oldAutoClear = renderer.autoClear;
		renderer.autoClear = false;
		this.fsQuad.material = this.material;
		this.uniforms.opacity.value = this.opacity;
		this.uniforms.tDiffuse.value = this.map;
		this.material.transparent = (this.opacity < 1.0);
		renderer.setRenderTarget(this.renderToScreen ? null : readBuffer);
		if (this.clear) renderer.clear();
		this.fsQuad.render(renderer);
		renderer.autoClear = oldAutoClear;
	}

	public function dispose() {
		this.material.dispose();
		this.fsQuad.dispose();
	}
}

@:expose("TexturePass")
class TexturePassExtern {
}