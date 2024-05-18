package three.examples.javascript.postprocessing;

import three.ShaderMaterial;
import three.UniformsUtils;
import three.pass.Pass;
import three.pass.FullScreenQuad;
import three.shaders.FilmShader;

class FilmPass extends Pass {
    public var intensity:Float;
    public var grayscale:Bool;
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(intensity:Float = 0.5, grayscale:Bool = false) {
        super();

        var shader:FilmShader = FilmShader.getInstance();

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

    public function render(renderer:Renderer, writeBuffer:RenderTexture, readBuffer:RenderTexture, deltaTime:Float /*, maskActive:Bool */) {
        uniforms['tDiffuse'].value = readBuffer.texture;
        uniforms['time'].value += deltaTime;

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