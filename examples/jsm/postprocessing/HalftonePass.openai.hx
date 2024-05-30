package three.js.examples.jsm.postprocessing;

import three-js.ShaderMaterial;
import three-js.UniformsUtils;
import Pass;
import FullScreenQuad;
import shaders.HalftoneShader;

class HalftonePass extends Pass {

    public function new(width:Int, height:Int, params:Dynamic) {
        super();
        uniforms = UniformsUtils.clone(HalftoneShader.uniforms);
        material = new ShaderMaterial(uniforms, HalftoneShader.fragmentShader, HalftoneShader.vertexShader);

        // set params
        uniforms.width.value = width;
        uniforms.height.value = height;

        for (key in Reflect.fields(params)) {
            if (Reflect.hasField(params, key) && Reflect.hasField(uniforms, key)) {
                Reflect.setField(uniforms, key, Reflect.field(params, key));
            }
        }

        fsQuad = new FullScreenQuad(material);
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic)/*, deltaTime:Float, maskActive:Bool*/ {
        material.uniforms.get('tDiffuse').value = readBuffer.texture;

        if (renderToScreen) {
            renderer.setRenderTarget(null);
            fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (clear) renderer.clear();
            fsQuad.render(renderer);
        }
    }

    public function setSize(width:Int, height:Int) {
        uniforms.width.value = width;
        uniforms.height.value = height;
    }

    public function dispose() {
        material.dispose();
        fsQuad.dispose();
    }
}