import three.ShaderMaterial;
import three.UniformsUtils;
import postprocessing.Pass;
import postprocessing.FullScreenQuad;
import shaders.HalftoneShader;

class HalftonePass extends Pass {

    public function new(width: Float, height: Float, params: Dynamic) {
        super();

        this.uniforms = UniformsUtils.clone(HalftoneShader.uniforms);
        this.material = new ShaderMaterial({
            uniforms: this.uniforms,
            fragmentShader: HalftoneShader.fragmentShader,
            vertexShader: HalftoneShader.vertexShader
        });

        this.uniforms.width.value = width;
        this.uniforms.height.value = height;

        for (key in Reflect.fields(params)) {
            if (Reflect.hasField(this.uniforms, key)) {
                this.uniforms[key].value = Reflect.field(params, key);
            }
        }

        this.fsQuad = new FullScreenQuad(this.material);
    }

    public function render(renderer: Renderer, writeBuffer: RenderTarget, readBuffer: RenderTarget) {
        this.material.uniforms['tDiffuse'].value = readBuffer.texture;

        if (this.renderToScreen) {
            renderer.setRenderTarget(null);
            this.fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (this.clear) renderer.clear();
            this.fsQuad.render(renderer);
        }
    }

    public function setSize(width: Float, height: Float): Void {
        this.uniforms.width.value = width;
        this.uniforms.height.value = height;
    }

    public function dispose(): Void {
        this.material.dispose();
        this.fsQuad.dispose();
    }
}