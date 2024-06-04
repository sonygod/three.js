import three.extras.passes.Pass;
import three.extras.passes.FullScreenQuad;
import three.materials.ShaderMaterial;
import three.materials.MeshBasicMaterial;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.cameras.Camera;
import three.textures.Texture;
import three.renderers.WebGLRenderTarget;
import three.constants.Constants;
import three.math.Vector2;
import three.uniforms.UniformsUtils;
import three.shaders.AfterimageShader;
import three.math.Color;
import three.materials.Material;

class AfterimagePass extends Pass {

    public var damp:Float;
    public var uniforms:three.uniforms.IUniforms;
    public var textureComp:WebGLRenderTarget;
    public var textureOld:WebGLRenderTarget;
    public var compFsMaterial:ShaderMaterial;
    public var compFsQuad:FullScreenQuad;
    public var copyFsMaterial:MeshBasicMaterial;
    public var copyFsQuad:FullScreenQuad;

    public function new(damp:Float = 0.96) {
        super();
        this.damp = damp;
        this.shader = AfterimageShader;
        this.uniforms = UniformsUtils.clone(this.shader.uniforms);
        this.uniforms["damp"].value = this.damp;
        this.textureComp = new WebGLRenderTarget(Std.int(js.Browser.window.innerWidth), Std.int(js.Browser.window.innerHeight), {
            magFilter: Constants.NearestFilter,
            type: Constants.HalfFloatType
        });
        this.textureOld = new WebGLRenderTarget(Std.int(js.Browser.window.innerWidth), Std.int(js.Browser.window.innerHeight), {
            magFilter: Constants.NearestFilter,
            type: Constants.HalfFloatType
        });
        this.compFsMaterial = new ShaderMaterial({
            uniforms: this.uniforms,
            vertexShader: this.shader.vertexShader,
            fragmentShader: this.shader.fragmentShader
        });
        this.compFsQuad = new FullScreenQuad(this.compFsMaterial);
        this.copyFsMaterial = new MeshBasicMaterial();
        this.copyFsQuad = new FullScreenQuad(this.copyFsMaterial);
    }

    public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, ?deltaTime:Float, ?maskActive:Bool) {
        this.uniforms["tOld"].value = this.textureOld.texture;
        this.uniforms["tNew"].value = readBuffer.texture;
        renderer.setRenderTarget(this.textureComp);
        this.compFsQuad.render(renderer);
        this.copyFsQuad.material.map = this.textureComp.texture;
        if (this.renderToScreen) {
            renderer.setRenderTarget(null);
            this.copyFsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (this.clear) renderer.clear();
            this.copyFsQuad.render(renderer);
        }
        // Swap buffers.
        var temp = this.textureOld;
        this.textureOld = this.textureComp;
        this.textureComp = temp;
        // Now textureOld contains the latest image, ready for the next frame.
    }

    public function setSize(width:Int, height:Int) {
        this.textureComp.setSize(width, height);
        this.textureOld.setSize(width, height);
    }

    public function dispose() {
        this.textureComp.dispose();
        this.textureOld.dispose();
        this.compFsMaterial.dispose();
        this.copyFsMaterial.dispose();
        this.compFsQuad.dispose();
        this.copyFsQuad.dispose();
    }
}