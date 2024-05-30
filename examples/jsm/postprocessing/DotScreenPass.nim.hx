import three.js.examples.jsm.postprocessing.Pass;
import three.js.examples.jsm.postprocessing.FullScreenQuad;
import three.js.examples.jsm.shaders.DotScreenShader;
import three.js.ShaderMaterial;
import three.js.UniformsUtils;

class DotScreenPass extends Pass {

	public var uniforms:Dynamic;
	public var material:ShaderMaterial;
	public var fsQuad:FullScreenQuad;

	public function new(center:Dynamic, angle:Float, scale:Float) {

		super();

		var shader = DotScreenShader;

		this.uniforms = UniformsUtils.clone(shader.uniforms);

		if (center != null) this.uniforms['center'].value.copy(center);
		if (angle != null) this.uniforms['angle'].value = angle;
		if (scale != null) this.uniforms['scale'].value = scale;

		this.material = new ShaderMaterial({

			name: shader.name,
			uniforms: this.uniforms,
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader

		});

		this.fsQuad = new FullScreenQuad(this.material);

	}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic /*, deltaTime:Dynamic, maskActive:Dynamic */) {

		this.uniforms['tDiffuse'].value = readBuffer.texture;
		this.uniforms['tSize'].value.set(readBuffer.width, readBuffer.height);

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