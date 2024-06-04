import three.extras.passes.Pass;
import three.extras.passes.FullScreenQuad;
import three.materials.ShaderMaterial;
import three.shaders.CopyShader;
import three.renderers.WebGLRenderTarget;
import three.constants.Blending;
import three.constants.TextureDataType;
import three.math.UniformsUtils;

class SavePass extends Pass {

	public var textureID:String = "tDiffuse";
	public var uniforms:Dynamic;
	public var material:ShaderMaterial;
	public var renderTarget:WebGLRenderTarget;
	public var fsQuad:FullScreenQuad;

	public function new(renderTarget:WebGLRenderTarget) {
		super();

		var shader = CopyShader;

		this.uniforms = UniformsUtils.clone(shader.uniforms);

		this.material = new ShaderMaterial({
			uniforms: this.uniforms,
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader,
			blending: Blending.NoBlending
		});

		this.renderTarget = renderTarget;

		if (this.renderTarget == null) {
			this.renderTarget = new WebGLRenderTarget(1, 1, {type: TextureDataType.HalfFloat});
			this.renderTarget.texture.name = "SavePass.rt";
		}

		this.needsSwap = false;
		this.fsQuad = new FullScreenQuad(this.material);
	}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic) {
		if (this.uniforms[this.textureID]) {
			this.uniforms[this.textureID].value = readBuffer.texture;
		}

		renderer.setRenderTarget(this.renderTarget);
		if (this.clear) renderer.clear();
		this.fsQuad.render(renderer);
	}

	public function setSize(width:Int, height:Int) {
		this.renderTarget.setSize(width, height);
	}

	public function dispose() {
		this.renderTarget.dispose();
		this.material.dispose();
		this.fsQuad.dispose();
	}
}