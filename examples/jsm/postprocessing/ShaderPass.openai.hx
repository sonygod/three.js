package three.js.examples.jspm.postprocessing;

import three.js.materials.ShaderMaterial;
import three.js.utils.UniformsUtils;
import Pass;
import FullScreenQuad;

class ShaderPass extends Pass {
    public var textureID:String;
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(shader:Dynamic, textureID:String = 'tDiffuse') {
        super();

        this.textureID = (textureID != null) ? textureID : 'tDiffuse';

        if (Std.isOfType(shader, ShaderMaterial)) {
            this.uniforms = shader.uniforms;
            this.material = shader;
        } else if (shader != null) {
            this.uniforms = UniformsUtils.clone(shader.uniforms);
            this.material = new ShaderMaterial({
                name: (shader.name != null) ? shader.name : 'unspecified',
                defines: Std.objectMerge({}, shader.defines),
                uniforms: this.uniforms,
                vertexShader: shader.vertexShader,
                fragmentShader: shader.fragmentShader
            });
        }

        this.fsQuad = new FullScreenQuad(this.material);
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic /*, deltaTime:Float, maskActive:Bool*/) {
        if (this.uniforms[this.textureID] != null) {
            this.uniforms[this.textureID].value = readBuffer.texture;
        }

        this.fsQuad.material = this.material;

        if (this.renderToScreen) {
            renderer.setRenderTarget(null);
            this.fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            // TODO: Avoid using autoClear properties, see https://github.com/mrdoob/three.js/pull/15571#issuecomment-465669600
            if (this.clear) renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
            this.fsQuad.render(renderer);
        }
    }

    public function dispose() {
        this.material.dispose();
        this.fsQuad.dispose();
    }
}