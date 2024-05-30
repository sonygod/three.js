import three.ShaderMaterial;
import three.UniformsUtils;
import three.examples.jsm.postprocessing.Pass;
import three.examples.jsm.postprocessing.FullScreenQuad;
import three.examples.jsm.shaders.FilmShader;

class FilmPass extends Pass {

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

	public function render(renderer:Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float /*, maskActive */) {

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

typedef Renderer = {
	// 这里需要定义Renderer的类型，因为它在JavaScript代码中没有定义
}

typedef WebGLRenderTarget = {
	// 这里需要定义WebGLRenderTarget的类型，因为它在JavaScript代码中没有定义
}