import three.ShaderMaterial;
import three.UniformsUtils;
import three.WebGLRenderTarget;
import three.WebGLRenderer;
import three.Texture;

import three.passes.Pass;
import three.passes.FullScreenQuad;

import three.shaders.FilmShader;

class FilmPass extends Pass {

    public var intensity:Float;
    public var grayscale:Bool;

    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(intensity:Float = 0.5, grayscale:Bool = false) {
        super();

        this.intensity = intensity;
        this.grayscale = grayscale;

        var shader = FilmShader;
        this.uniforms = UniformsUtils.clone(shader.uniforms);

        this.material = new ShaderMaterial({
            name: shader.name,
            uniforms: this.uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });

        this.uniforms.intensity.value = intensity;
        this.uniforms.grayscale.value = grayscale;

        this.fsQuad = new FullScreenQuad(this.material);
    }

    public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float):Void {
        this.uniforms['tDiffuse'].value = readBuffer.texture;
        this.uniforms['time'].value += deltaTime;

        if (this.renderToScreen) {
            renderer.setRenderTarget(null);
            this.fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (this.clear) renderer.clear();
            this.fsQuad.render(renderer);
        }
    }

    public function dispose():Void {
        this.material.dispose();
        this.fsQuad.dispose();
    }
}