import three.ShaderMaterial;
import three.UniformsUtils;
import Postprocessing.Pass;
import Postprocessing.FullScreenQuad;
import Shaders.CopyShader;

class TexturePass extends Pass {

    public var map:three.Texture;
    public var opacity:Float;
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(map:three.Texture, opacity:Float = 1.0) {
        super();

        var shader:Dynamic = CopyShader;

        this.map = map;
        this.opacity = opacity;

        this.uniforms = UniformsUtils.clone(shader.uniforms);

        this.material = new ShaderMaterial({
            uniforms: this.uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            depthTest: false,
            depthWrite: false,
            transparent: this.opacity < 1.0,
            premultipliedAlpha: true
        });

        this.needsSwap = false;

        this.fsQuad = new FullScreenQuad(null);
    }

    public function render(renderer:three.WebGLRenderer, writeBuffer:three.WebGLRenderTarget, readBuffer:three.WebGLRenderTarget) {
        var oldAutoClear:Bool = renderer.autoClear;
        renderer.autoClear = false;

        this.fsQuad.material = this.material;

        this.uniforms["opacity"].value = this.opacity;
        this.uniforms["tDiffuse"].value = this.map;
        this.material.transparent = (this.opacity < 1.0);

        renderer.setRenderTarget(this.renderToScreen ? null : readBuffer);
        if (this.clear) renderer.clear();
        this.fsQuad.render(renderer);

        renderer.autoClear = oldAutoClear;
    }

    public function dispose() {
        this.material.dispose();
        this.fsQuad.dispose();
    }
}