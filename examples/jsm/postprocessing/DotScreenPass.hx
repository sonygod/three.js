package three.examples.jsm.postprocessing;

import three.ShaderMaterial;
import three.UniformsUtils;
import Pass;
import FullScreenQuad;
import shaders.DotScreenShader;

class DotScreenPass extends Pass {
    public function new(center:Vector2, angle:Float, scale:Float) {
        super();

        var shader:DotScreenShader = DotScreenShader.getInstance();

        uniforms = UniformsUtils.clone(shader.uniforms);

        if (center != null) uniforms.get('center').value.copyFrom(center);
        if (angle != null) uniforms.get('angle').value = angle;
        if (scale != null) uniforms.get('scale').value = scale;

        material = new ShaderMaterial({
            name: shader.name,
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });

        fsQuad = new FullScreenQuad(material);
    }

    public function render(renderer:three.Renderer, writeBuffer:three.RenderTarget, readBuffer:three.RenderTarget /*, deltaTime:Float, maskActive:Bool */):Void {
        uniforms.get('tDiffuse').value = readBuffer.texture;
        uniforms.get('tSize').value.set(readBuffer.width, readBuffer.height);

        if (renderToScreen) {
            renderer.setRenderTarget(null);
            fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (clear) renderer.clear();
            fsQuad.render(renderer);
        }
    }

    public function dispose():Void {
        material.dispose();
        fsQuad.dispose();
    }
}

// export
#if haxe3
@:keep
#else
@:native
#end
class DotScreenPass extends Pass {}