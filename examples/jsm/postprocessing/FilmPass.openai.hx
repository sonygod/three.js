package three.js.examples.jsm.postprocessing;

import three.js.shaders.FilmShader;
import three.js.materials.ShaderMaterial;
import three.js.utils.UniformsUtils;
import three.js.postprocessing.Pass;
import three.js.postprocessing.FullScreenQuad;

class FilmPass extends Pass {
    var intensity:Float = 0.5;
    var grayscale:Bool = false;

    public function new(?intensity:Float = 0.5, ?grayscale:Bool = false) {
        super();
        var shader = FilmShader.getInstance();
        uniforms = UniformsUtils.clone(shader.uniforms);
        material = new ShaderMaterial({
            name: shader.name,
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });
        uniforms.intensity.value = intensity;
        uniforms.grayscale.value = grayscale;
        fsQuad = new FullScreenQuad(material);
    }

    override public function render(renderer:Renderer, writeBuffer:Texture, readBuffer:Texture, deltaTime:Float):Void {
        uniforms.get('tDiffuse').value = readBuffer;
        uniforms.get('time').value += deltaTime;
        if (renderToScreen) {
            renderer.setRenderTarget(null);
            fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (clear) {
                renderer.clear();
            }
            fsQuad.render(renderer);
        }
    }

    override public function dispose():Void {
        material.dispose();
        fsQuad.dispose();
    }
}