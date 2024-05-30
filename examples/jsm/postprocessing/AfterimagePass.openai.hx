package three.js.examples.jsm.postprocessing;

import three.js.Renderer;
import three.js.WebGLRenderTarget;
import three.js.Material;
import three.js.ShaderMaterial;
import three.js.MeshBasicMaterial;
import three.js.UniformsUtils;
import three.js.NearestFilter;
import three.js.HalfFloatType;
import Pass;
import FullScreenQuad;
import AfterimageShader;

class AfterimagePass extends Pass {
    public var shader:AfterimageShader;
    public var uniforms:Dynamic;
    public var textureComp:WebGLRenderTarget;
    public var textureOld:WebGLRenderTarget;
    public var compFsMaterial:ShaderMaterial;
    public var compFsQuad:FullScreenQuad;
    public var copyFsMaterial:MeshBasicMaterial;
    public var copyFsQuad:FullScreenQuad;
    public var damp:Float;

    public function new(damp:Float = 0.96) {
        super();
        this.shader = AfterimageShader;
        this.uniforms = UniformsUtils.clone(shader.uniforms);
        this.uniforms['damp'].value = damp;

        this.textureComp = new WebGLRenderTarget(Std.int(browser.window.innerWidth), Std.int(browser.window.innerHeight), {
            magFilter: NearestFilter,
            type: HalfFloatType
        });

        this.textureOld = new WebGLRenderTarget(Std.int(browser.window.innerWidth), Std.int(browser.window.innerHeight), {
            magFilter: NearestFilter,
            type: HalfFloatType
        });

        this.compFsMaterial = new ShaderMaterial({
            uniforms: this.uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });

        this.compFsQuad = new FullScreenQuad(this.compFsMaterial);

        this.copyFsMaterial = new MeshBasicMaterial();
        this.copyFsQuad = new FullScreenQuad(this.copyFsMaterial);
    }

    public function render(renderer:Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
        this.uniforms['tOld'].value = this.textureOld.texture;
        this.uniforms['tNew'].value = readBuffer.texture;

        renderer.setRenderTarget(this.textureComp);
        this.compFsQuad.render(renderer);

        this.copyFsQuad.material.map = this.textureComp.texture;

        if (this.renderToScreen) {
            renderer.setRenderTarget(null);
            this.copyFsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (this.clear) renderer.clear();
            this.copyFsQuad.render(renderer);
        }

        // Swap buffers.
        var temp = this.textureOld;
        this.textureOld = this.textureComp;
        this.textureComp = temp;
    }

    public function setSize(width:Int, height:Int) {
        this.textureComp.setSize(width, height);
        this.textureOld.setSize(width, height);
    }

    public function dispose() {
        this.textureComp.dispose();
        this.textureOld.dispose();
        this.compFsMaterial.dispose();
        this.copyFsMaterial.dispose();
        this.compFsQuad.dispose();
        this.copyFsQuad.dispose();
    }
}