import three.HalfFloatType;
import three.NoBlending;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.WebGLRenderTarget;
import three.examples.jsm.postprocessing.Pass;
import three.examples.jsm.postprocessing.FullScreenQuad;
import three.examples.jsm.shaders.CopyShader;

class SavePass extends Pass {

	public function new(renderTarget:WebGLRenderTarget) {

		super();

		var shader = CopyShader;

		var textureID = 'tDiffuse';

		var uniforms = UniformsUtils.clone(shader.uniforms);

		var material = new ShaderMaterial({

			uniforms: uniforms,
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader,
			blending: NoBlending

		});

		if (renderTarget == null) {

			renderTarget = new WebGLRenderTarget(1, 1, { type: HalfFloatType }); // will be resized later
			renderTarget.texture.name = 'SavePass.rt';

		}

		this.needsSwap = false;

		var fsQuad = new FullScreenQuad(material);

	}

	public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget/*, deltaTime:Float, maskActive:Bool */) {

		if (this.uniforms[textureID] != null) {

			this.uniforms[textureID].value = readBuffer.texture;

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