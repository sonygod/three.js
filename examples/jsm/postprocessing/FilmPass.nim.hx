import three.js.examples.jsm.postprocessing.Pass;
import three.js.examples.jsm.postprocessing.FullScreenQuad;
import three.js.examples.jsm.shaders.FilmShader;
import three.js.ShaderMaterial;
import three.js.UniformsUtils;

class FilmPass extends Pass {

	public var uniforms:Dynamic;
	public var material:ShaderMaterial;
	public var fsQuad:FullScreenQuad;

	public function new(intensity:Float = 0.5, grayscale:Bool = false) {

		super();

		var shader = FilmShader;

		this.uniforms = UniformsUtils.clone(shader.uniforms);

		this.material = new ShaderMaterial({

			name: shader.name,
			uniforms: this.uniforms,
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader

		});

		this.uniforms.intensity.value = intensity; // (0 = no effect, 1 = full effect)
		this.uniforms.grayscale.value = grayscale;

		this.fsQuad = new FullScreenQuad(this.material);

	}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, deltaTime:Float /*, maskActive */) {

		this.uniforms['tDiffuse'].value = readBuffer.texture;
		this.uniforms['time'].value += deltaTime;

		if (this.renderToScreen) {

			renderer.setRenderTarget(null);
			this.fsQuad.render(renderer);

		} else {

			renderer.setRenderTarget(writeBuffer);
			if (this.clear) renderer.clear();
			this.fsQuad.render(renderer);

		}

	}

	public function dispose() {

		this.material.dispose();

		this.fsQuad.dispose();

	}

}