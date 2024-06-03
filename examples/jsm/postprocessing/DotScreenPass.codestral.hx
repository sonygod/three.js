import three.ShaderMaterial;
import three.UniformsUtils;
import three.postprocessing.Pass;
import three.postprocessing.FullScreenQuad;
import three.shaders.DotScreenShader;

class DotScreenPass extends Pass {

    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(center:Vector3 = null, angle:Float = NaN, scale:Float = NaN) {
        super();

        var shader = DotScreenShader;

        this.uniforms = UniformsUtils.clone(shader.uniforms);

        if (center != null) this.uniforms['center'].value.copy(center);
        if (!isNaN(angle)) this.uniforms['angle'].value = angle;
        if (!isNaN(scale)) this.uniforms['scale'].value = scale;

        this.material = new ShaderMaterial({
            name: shader.name,
            uniforms: this.uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });

        this.fsQuad = new FullScreenQuad(this.material);
    }

    public function render(renderer, writeBuffer, readBuffer) {
        this.uniforms['tDiffuse'].value = readBuffer.texture;
        this.uniforms['tSize'].value.set(readBuffer.width, readBuffer.height);

        if (this.renderToScreen) {
            renderer.setRenderTarget(null);
            this.fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (this.clear) renderer.clear();
            this.fsQuad.render(renderer);
        }
    }

    public function dispose() {
        this.material.dispose();
        this.fsQuad.dispose();
    }
}