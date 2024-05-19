package three.js.examples.jsm.postprocessing;

import three.js.Three;
import three.js.renderers.WebGLRenderTarget;
import three.js.materials.MeshBasicMaterial;
import three.js.materials.ShaderMaterial;
import three.js.utils.UniformsUtils;
import three.js.postprocessing.Pass;
import three.js.postprocessing.FullScreenQuad;

class AfterimagePass extends Pass {
    public var shader:AfterimageShader;
    public var uniforms:Dynamic;
    public var textureComp:WebGLRenderTarget;
    public var textureOld:WebGLRenderTarget;
    public var compFsMaterial:ShaderMaterial;
    public var compFsQuad:FullScreenQuad;
    public var copyFsMaterial:MeshBasicMaterial;
    public var copyFsQuad:FullScreenQuad;
    public var renderToScreen:Bool;
    public var clear:Bool;

    public function new(damp:Float = 0.96) {
        super();
        shader = new AfterimageShader();
        uniforms = UniformsUtils.clone(shader.uniforms);
        uniforms['damp'].value = damp;

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

        copyFsMaterial = new MeshBasicMaterial();
        copyFsQuad = new FullScreenQuad(copyFsMaterial);
    }

    public function render(renderer:Three.WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget/*, deltaTime:Float, maskActive:Bool*/) {
        uniforms['tOld'].value = textureOld.texture;
        uniforms['tNew'].value = readBuffer.texture;

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
        // Now textureOld contains the latest image, ready for the next frame.
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