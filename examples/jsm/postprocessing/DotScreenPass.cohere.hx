import js.three.ShaderMaterial;
import js.three.UniformsUtils;
import js.Pass;
import js.FullScreenQuad;
import js.DotScreenShader;

class DotScreenPass extends Pass {
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(center:Dynamic, angle:Float, scale:Float) {
        super();
        var shader = DotScreenShader;
        uniforms = UniformsUtils.clone(shader.uniforms);
        if (center != null) uniforms.center.value.copy(center);
        if (angle != null) uniforms.angle.value = angle;
        if (scale != null) uniforms.scale.value = scale;
        material = ShaderMaterial({
            name: shader.name,
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });
        fsQuad = FullScreenQuad(material);
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, deltaTime:Float, maskActive:Bool) {
        uniforms.tDiffuse.value = readBuffer.texture;
        uniforms.tSize.value.set(readBuffer.width, readBuffer.height);
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

class Export {
    public static function get DotScreenPass() DotScreenPass;
}