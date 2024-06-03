package threejs.examples.jsm.postprocessing;

import threejs.three.ShaderMaterial;
import threejs.three.UniformsUtils;
import threejs.examples.jsm.postprocessing.Pass;
import threejs.examples.jsm.postprocessing.FullScreenQuad;

class ShaderPass extends Pass {
    public var textureID:String;
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(shader:Dynamic, textureID:String = "tDiffuse") {
        super();

        this.textureID = textureID;

        if (Std.is(shader, ShaderMaterial)) {
            this.uniforms = shader.uniforms;
            this.material = shader;
        } else if (shader != null) {
            this.uniforms = UniformsUtils.clone(shader.uniforms);

            var name = (shader.name != null) ? shader.name : "unspecified";
            var defines = js.Boot.clone(shader.defines);

            this.material = new ShaderMaterial({
                name: name,
                defines: defines,
                uniforms: this.uniforms,
                vertexShader: shader.vertexShader,
                fragmentShader: shader.fragmentShader
            });
        }

        this.fsQuad = new FullScreenQuad(this.material);
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic) {
        if (this.uniforms.hasOwnProperty(this.textureID)) {
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