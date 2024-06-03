import three.HalfFloatType;
import three.NoBlending;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.WebGLRenderTarget;
import three.pass.Pass;
import three.pass.FullScreenQuad;
import three.shaders.CopyShader;

class SavePass extends Pass {

    public var textureID:String;
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var renderTarget:WebGLRenderTarget;
    public var fsQuad:FullScreenQuad;

    public function new(renderTarget:WebGLRenderTarget) {
        super();

        var shader = CopyShader;

        this.textureID = 'tDiffuse';

        this.uniforms = UniformsUtils.clone(shader.uniforms);

        this.material = new ShaderMaterial({
            uniforms: this.uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            blending: NoBlending
        });

        this.renderTarget = renderTarget;

        if (this.renderTarget == null) {
            this.renderTarget = new WebGLRenderTarget(1, 1, { type: HalfFloatType });
            this.renderTarget.texture.name = 'SavePass.rt';
        }

        this.needsSwap = false;

        this.fsQuad = new FullScreenQuad(this.material);
    }

    public function render(renderer:any, writeBuffer:any, readBuffer:any) {
        if (this.uniforms[this.textureID] != null) {
            this.uniforms[this.textureID].value = readBuffer.texture;
        }

        renderer.setRenderTarget(this.renderTarget);
        if (this.clear) renderer.clear();
        this.fsQuad.render(renderer);
    }

    public function setSize(width:Int, height:Int) {
        this.renderTarget.setSize(width, height);
    }

    public function dispose() {
        this.renderTarget.dispose();
        this.material.dispose();
        this.fsQuad.dispose();
    }
}