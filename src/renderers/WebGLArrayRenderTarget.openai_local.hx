import three.renderers.WebGLRenderTarget;
import three.textures.DataArrayTexture;

class WebGLArrayRenderTarget extends WebGLRenderTarget {

    public var isWebGLArrayRenderTarget:Bool;
    public var depth:Int;
    public var texture:DataArrayTexture;

    public function new(width:Int = 1, height:Int = 1, depth:Int = 1, options:Dynamic = null) {
        super(width, height, options);

        this.isWebGLArrayRenderTarget = true;
        this.depth = depth;

        this.texture = new DataArrayTexture(null, width, height, depth);
        this.texture.isRenderTargetTexture = true;
    }

}