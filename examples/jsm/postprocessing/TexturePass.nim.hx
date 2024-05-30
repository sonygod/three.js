import three.js.examples.jsm.postprocessing.Pass;
import three.js.examples.jsm.postprocessing.FullScreenQuad;
import three.js.examples.jsm.shaders.CopyShader;
import three.js.ShaderMaterial;
import three.js.UniformsUtils;

class TexturePass extends Pass {

	public var map:Dynamic;
	public var opacity:Float;
	public var uniforms:Dynamic;
	public var material:ShaderMaterial;
	public var fsQuad:FullScreenQuad;

	public function new(map:Dynamic, opacity:Float = 1.0) {
		super();

		var shader = CopyShader;

		this.map = map;
		this.opacity = opacity;

		this.uniforms = UniformsUtils.clone(shader.uniforms);

		this.material = new ShaderMaterial({
			uniforms: this.uniforms,
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader,
			depthTest: false,
			depthWrite: false,
			premultipliedAlpha: true
		});

		this.needsSwap = false;

		this.fsQuad = new FullScreenQuad(null);
	}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic /*, deltaTime:Dynamic, maskActive:Dynamic */) {
		var oldAutoClear = renderer.autoClear;
		renderer.autoClear = false;

		this.fsQuad.material = this.material;

		this.uniforms['opacity'].value = this.opacity;
		this.uniforms['tDiffuse'].value = this.map;
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