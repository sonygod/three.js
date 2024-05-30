import js.threes.ShaderMaterial;
import js.threes.UniformsUtils;
import js.threes.Pass;
import js.threes.FullScreenQuad;

class ShaderPass extends Pass {
    var textureID:String;
    var uniforms:Dynamic;
    var material:ShaderMaterial;
    var fsQuad:FullScreenQuad;

    public function new(shader:ShaderMaterial, textureID:String) {
        super();
        this.textureID = textureID != null ? textureID : 'tDiffuse';

        if (shader != null) {
            if (shader instanceof ShaderMaterial) {
                this.uniforms = shader.uniforms;
                this.material = shader;
            } else {
                this.uniforms = UniformsUtils.clone(shader.uniforms);
                this.material = ShaderMaterial({
                    name: shader.name != null ? shader.name : 'unspecified',
                    defines: shader.defines,
                    uniforms: this.uniforms,
                    vertexShader: shader.vertexShader,
                    fragmentShader: shader.fragmentShader
                });
            }
        }

        this.fsQuad = FullScreenQuad(this.material);
    }

    public function render(renderer, writeBuffer, readBuffer) {
        if (this.uniforms[this.textureID] != null) {
            this.uniforms[this.textureID].value = readBuffer.texture;
        }

        this.fsQuad.material = this.material;

        if (this.renderToScreen) {
            renderer.setRenderTarget(null);
            this.fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (this.clear) {
                renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
            }
            this.fsQuad.render(renderer);
        }
    }

    public function dispose() {
        this.material.dispose();
        this.fsQuad.dispose();
    }
}

class ShaderPassDefinition {
    static public function __init__() {
        js.threes.ShaderPass = ShaderPass;
    }
}