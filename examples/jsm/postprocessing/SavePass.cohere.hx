import js.three.WebGLRenderTarget;
import js.three.ShaderMaterial;
import js.three.UniformsUtils;
import js.three.NoBlending;
import js.three.HalfFloatType;
import js.three.Pass;
import js.three.FullScreenQuad;
import js.three.CopyShader;

class SavePass extends Pass {
    public var textureID:String = 'tDiffuse';
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var renderTarget:WebGLRenderTarget;
    public var needsSwap:Bool;
    public var fsQuad:FullScreenQuad;

    public function new(renderTarget:WebGLRenderTarget) {
        super();
        var shader = CopyShader;
        uniforms = js.Reflect.field(shader, 'uniforms');
        material = js.Reflect.construct(ShaderMaterial, {
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            blending: NoBlending
        });
        this.renderTarget = (renderTarget == null) ? new WebGLRenderTarget(1, 1, { type: HalfFloatType }) : renderTarget;
        this.renderTarget.texture.name = 'SavePass.rt';
        needsSwap = false;
        fsQuad = new FullScreenQuad(material);
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic):Void {
        if (js.Reflect.field(uniforms, textureID) != null) {
            js.Reflect.setField(uniforms, textureID, readBuffer.texture);
        }
        renderer.setRenderTarget(renderTarget);
        if (js.Reflect.field(this, 'clear') != null) renderer.clear();
        fsQuad.render(renderer);
    }

    public function setSize(width:Int, height:Int):Void {
        renderTarget.setSize(width, height);
    }

    public function dispose():Void {
        renderTarget.dispose();
        material.dispose();
        fsQuad.dispose();
    }
}

class Export {
    public static function get SavePass() {
        return SavePass;
    }
}