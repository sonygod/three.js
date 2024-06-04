import three.ShaderMaterial;
import three.UniformsUtils;
import three.extras.passes.Pass;
import three.extras.passes.FullScreenQuad;
import three.shaders.HalftoneShader;

/**
 * RGB Halftone pass for three.js effects composer. Requires HalftoneShader.
 */
class HalftonePass extends Pass {
  public var uniforms: {
    tDiffuse: Dynamic<three.Texture>;
    width: Dynamic<Float>;
    height: Dynamic<Float>;
    scale: Dynamic<Float>;
    radius: Dynamic<Float>;
    angle: Dynamic<Float>;
  };

  public var material: ShaderMaterial;

  public var fsQuad: FullScreenQuad;

  public function new(width: Float, height: Float, params: {
    scale: Float;
    radius: Float;
    angle: Float;
  }) {
    super();
    this.uniforms = UniformsUtils.clone(HalftoneShader.uniforms);
    this.material = new ShaderMaterial({
      uniforms: this.uniforms,
      fragmentShader: HalftoneShader.fragmentShader,
      vertexShader: HalftoneShader.vertexShader
    });
    this.uniforms.width.value = width;
    this.uniforms.height.value = height;
    this.uniforms.scale.value = params.scale;
    this.uniforms.radius.value = params.radius;
    this.uniforms.angle.value = params.angle;
    this.fsQuad = new FullScreenQuad(this.material);
  }

  public function render(renderer: three.Renderer, writeBuffer: three.RenderTarget, readBuffer: three.RenderTarget, deltaTime: Float, maskActive: Bool) {
    this.material.uniforms.tDiffuse.value = readBuffer.texture;
    if (this.renderToScreen) {
      renderer.setRenderTarget(null);
      this.fsQuad.render(renderer);
    } else {
      renderer.setRenderTarget(writeBuffer);
      if (this.clear) renderer.clear();
      this.fsQuad.render(renderer);
    }
  }

  public function setSize(width: Float, height: Float) {
    this.uniforms.width.value = width;
    this.uniforms.height.value = height;
  }

  public function dispose() {
    this.material.dispose();
    this.fsQuad.dispose();
  }
}