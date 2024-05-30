import js.three.ShaderMaterial;
import js.three.UniformsUtils;

import js.Pass;
import js.FullScreenQuad;
import js.FilmShader;

class FilmPass extends Pass {
    public var intensity:Float = 0.5;
    public var grayscale:Bool = false;
    public var shader:FilmShader;
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new() {
        super();
        shader = FilmShader;
        uniforms = UniformsUtils.clone(shader.uniforms);
        material = ShaderMaterial({
            name: shader.name,
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });
        uniforms.intensity.value = intensity;
        uniforms.grayscale.value = grayscale;
        fsQuad = FullScreenQuad(material);
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, deltaTime:Float) {
        uniforms.tDiffuse.value = readBuffer.texture;
        uniforms.time.value += deltaTime;

        if (renderToScreen) {
            renderer.setRenderTarget(null);
            fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (clear) renderer.clear();
            fsQuad.render(renderer);
        }
    }

    public function dispose() {
        material.dispose();
        fsQuad.dispose();
    }
}