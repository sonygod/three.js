import three.ShaderMaterial;
import three.UniformsUtils;
import three.Vector2;
import three.Texture;
import three.WebGLRenderer;
import three.RenderTarget;
import three.FullScreenQuad;

import shaders.DotScreenShader;

class DotScreenPass extends Pass {

	public var uniforms: {
		tDiffuse: Texture,
		tSize: Vector2,
		center: Vector2,
		angle: Float,
		scale: Float
	};

	public var material: ShaderMaterial;
	public var fsQuad: FullScreenQuad;

	public function new(center: Vector2 = null, angle: Float = null, scale: Float = null) {
		super();

		var shader = DotScreenShader;

		this.uniforms = UniformsUtils.clone(shader.uniforms);

		if (center != null) this.uniforms.center.value = center;
		if (angle != null) this.uniforms.angle.value = angle;
		if (scale != null) this.uniforms.scale.value = scale;

		this.material = new ShaderMaterial({
			name: shader.name,
			uniforms: this.uniforms,
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader
		});

		this.fsQuad = new FullScreenQuad(this.material);
	}

	public function render(renderer: WebGLRenderer, writeBuffer: RenderTarget, readBuffer: RenderTarget, ?deltaTime: Float, ?maskActive: Bool): Void {
		this.uniforms.tDiffuse.value = readBuffer.texture;
		this.uniforms.tSize.value.set(readBuffer.width, readBuffer.height);

		if (this.renderToScreen) {
			renderer.setRenderTarget(null);
			this.fsQuad.render(renderer);
		} else {
			renderer.setRenderTarget(writeBuffer);
			if (this.clear) renderer.clear();
			this.fsQuad.render(renderer);
		}
	}

	public function dispose(): Void {
		this.material.dispose();
		this.fsQuad.dispose();
	}
}