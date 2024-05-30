package three.js.examples.jm.postprocessing;

import three.js.ShaderMaterial;
import three.js.UniformsUtils;
import three.js.Passes.Pass;
import three.js.Passes.FullScreenQuad;
import three.js.shaders.DotScreenShader;

class DotScreenPass extends Pass {
    public function new(center:Vector2, angle:Float, scale:Float) {
        super();

        var shader:DotScreenShader = DotScreenShader.instance;

        uniforms = UniformsUtils.clone(shader.uniforms);

        if (center != null) uniforms.get("center").value.copyFrom(center);
        if (angle != Math.NaN) uniforms.get("angle").value = angle;
        if (scale != Math.NaN) uniforms.get("scale").value = scale;

        material = new ShaderMaterial({
            name: shader.name,
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });

        fsQuad = new FullScreenQuad(material);
    }

    public function render(renderer:Renderer, writeBuffer:RenderTarget, readBuffer:RenderTarget /*, deltaTime:Float, maskActive:Bool */):Void {
        uniforms.get("tDiffuse").value = readBuffer.texture;
        uniforms.get("tSize").value.set(readBuffer.width, readBuffer.height);

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