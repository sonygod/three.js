import three.ShaderMaterial;
import three.UniformsUtils;
import postprocessing.Pass;
import postprocessing.FullScreenQuad;
import shaders.FilmShader;

class FilmPass extends Pass {

    public function new(intensity:Float = 0.5, grayscale:Bool = false) {
        super();

        var shader = FilmShader.instance;

        this.uniforms = UniformsUtils.clone(shader.uniforms);

        this.material = new ShaderMaterial( {
            name: shader.name,
            uniforms: this.uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        } );

        this.uniforms.get("intensity").value = intensity;
        this.uniforms.get("grayscale").value = grayscale;

        this.fsQuad = new FullScreenQuad(this.material);
    }

    public function render(renderer:Renderer, writeBuffer:RenderTarget, readBuffer:RenderTarget, deltaTime:Float) {
        this.uniforms.get("tDiffuse").value = readBuffer.texture;
        this.uniforms.get("time").value += deltaTime;

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