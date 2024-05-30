import js.three.ShaderMaterial;
import js.three.UniformsUtils;

import js.three.postprocessing.Pass;
import js.three.postprocessing.FullScreenQuad;
import js.three.shaders.HalftoneShader;

class HalftonePass extends Pass {
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(width:Int, height:Int, params:Dynamic) {
        super();

        uniforms = js.three.UniformsUtils.clone(js.three.shaders.HalftoneShader.uniforms);
        material = new ShaderMaterial({
            uniforms: uniforms,
            fragmentShader: js.three.shaders.HalftoneShader.fragmentShader,
            vertexShader: js.three.shaders.HalftoneShader.vertexShader
        });

        // set params
        uniforms.width.value = width;
        uniforms.height.value = height;

        for (key in params) {
            if (params.hasOwnProperty(key) && uniforms.hasOwnProperty(key)) {
                uniforms[key].value = params[key];
            }
        }

        fsQuad = new FullScreenQuad(material);
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic):Void {
        material.uniforms['tDiffuse'].value = readBuffer.texture;

        if (renderToScreen) {
            renderer.setRenderTarget(null);
            fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (clear) renderer.clear();
            fsQuad.render(renderer);
        }
    }

    public function setSize(width:Int, height:Int):Void {
        uniforms.width.value = width;
        uniforms.height.value = height;
    }

    public function dispose():Void {
        material.dispose();
        fsQuad.dispose();
    }
}

@:expose
class Exports {
    static function getHalftonePass():HalftonePass {
        return HalftonePass;
    }
}