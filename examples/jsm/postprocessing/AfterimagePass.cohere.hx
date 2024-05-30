import js.three.WebGLRenderTarget;
import js.three.ShaderMaterial;
import js.three.UniformsUtils;
import js.three.NearestFilter;
import js.three.HalfFloatType;

import js.three.Pass;
import js.three.FullScreenQuad;

import js.three.shaders.AfterimageShader;

class AfterimagePass extends Pass {

    var shader:AfterimageShader;
    var uniforms:Map<String, dynamic>;

    var textureComp:WebGLRenderTarget;
    var textureOld:WebGLRenderTarget;

    var compFsMaterial:ShaderMaterial;
    var compFsQuad:FullScreenQuad;

    var copyFsMaterial:ShaderMaterial;
    var copyFsQuad:FullScreenQuad;

    public function new(damp:Float = 0.96) {
        super();

        shader = AfterimageShader;
        uniforms = UniformsUtils.clone(shader.uniforms);
        uniforms.set('damp', damp);

        textureComp = new WebGLRenderTarget(Std.int(window.innerWidth), Std.int(window.innerHeight), {
            magFilter: NearestFilter,
            type: HalfFloatType
        });

        textureOld = new WebGLRenderTarget(Std.int(window.innerWidth), Std.int(window.innerHeight), {
            magFilter: NearestFilter,
            type: HalfFloatType
        });

        compFsMaterial = new ShaderMaterial({
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });

        compFsQuad = new FullScreenQuad(compFsMaterial);

        copyFsMaterial = new ShaderMaterial();
        copyFsQuad = new FullScreenQuad(copyFsMaterial);
    }

    public function render(renderer: dynamic, writeBuffer: dynamic, readBuffer: dynamic) {
        uniforms.set('tOld', textureOld.texture);
        uniforms.set('tNew', readBuffer.texture);

        renderer.setRenderTarget(textureComp);
        compFsQuad.render(renderer);

        copyFsQuad.material.map = textureComp.texture;

        if (renderToScreen) {
            renderer.setRenderTarget(null);
            copyFsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (clear) renderer.clear();
            copyFsQuad.render(renderer);
        }

        // Swap buffers.
        var temp = textureOld;
        textureOld = textureComp;
        textureComp = temp;
    }

    public function setSize(width:Int, height:Int) {
        textureComp.setSize(width, height);
        textureOld.setSize(width, height);
    }

    public function dispose() {
        textureComp.dispose();
        textureOld.dispose();

        compFsMaterial.dispose();
        copyFsMaterial.dispose();

        compFsQuad.dispose();
        copyFsQuad.dispose();
    }

}