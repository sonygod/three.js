package three.js.examples.jsm.postprocessing;

import three.js.Helpers;
import three.js.renderers.WebGLRenderTarget;
import three.js.materials.ShaderMaterial;
import three.js.materials.UniformsUtils;
import three.js.webgl.FullScreenQuad;
import shaders.CopyShader;

class SavePass extends Pass {
    public var textureID:String;
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var renderTarget:WebGLRenderTarget;
    public var fsQuad:FullScreenQuad;
    public var needsSwap:Bool;

    public function new(renderTarget:WebGLRenderTarget = null) {
        super();

        var shader:CopyShader = new CopyShader();

        textureID = 'tDiffuse';

        uniforms = UniformsUtils.clone(shader.uniforms);

        material = new ShaderMaterial({
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            blending: NoBlending
        });

        this.renderTarget = renderTarget;
        if (renderTarget == null) {
            renderTarget = new WebGLRenderTarget(1, 1, { type: HalfFloatType });
            renderTarget.texture.name = 'SavePass.rt';
        }

        needsSwap = false;

        fsQuad = new FullScreenQuad(material);
    }

    public function render(renderer: Renderer, writeBuffer:Texture, readBuffer:Texture /*, deltaTime:Float, maskActive:Bool */) {
        if (uniforms[textureID] != null) {
            uniforms[textureID].value = readBuffer.texture;
        }

        renderer.setRenderTarget(renderTarget);
        if (clear) renderer.clear();
        fsQuad.render(renderer);
    }

    public function setSize(width:Int, height:Int) {
        renderTarget.setSize(width, height);
    }

    public function dispose() {
        renderTarget.dispose();
        material.dispose();
        fsQuad.dispose();
    }
}