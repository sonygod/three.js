import three.ShaderMaterial;
import three.UniformsUtils;
import three.jsm.postprocessing.Pass;
import three.jsm.postprocessing.FullScreenQuad;

class ShaderPass extends Pass {

    public var textureID:String;
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(shader:Dynamic, textureID:String) {
        super();

        this.textureID = if (textureID != null) textureID else 'tDiffuse';

        if (shader instanceof ShaderMaterial) {
            this.uniforms = shader.uniforms;
            this.material = shader;
        } else if (shader != null) {
            this.uniforms = UniformsUtils.clone(shader.uniforms);
            this.material = new ShaderMaterial({
                name: if (shader.name != null) shader.name else 'unspecified',
                defines: shader.defines,
                uniforms: this.uniforms,
                vertexShader: shader.vertexShader,
                fragmentShader: shader.fragmentShader
            });
        }

        this.fsQuad = new FullScreenQuad(this.material);
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic) {
        if (this.uniforms[this.textureID] != null) {
            this.uniforms[this.textureID].value = readBuffer.texture;
        }

        this.fsQuad.material = this.material;

        if (this.renderToScreen) {
            renderer.setRenderTarget(null);
            this.fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (this.clear) renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
            this.fsQuad.render(renderer);
        }
    }

    public function dispose() {
        this.material.dispose();
        this.fsQuad.dispose();
    }
}