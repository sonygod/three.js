import js.Browser.window;
import js.Lib;
import three.renderers.WebGLRenderTarget;
import three.textures.Data3DTexture;

class WebGL3DRenderTarget extends WebGLRenderTarget {

    public var isWebGL3DRenderTarget:Bool;
    public var depth:Int;
    public var texture:Data3DTexture;

    public function new(width:Int = 1, height:Int = 1, depth:Int = 1, options:Dynamic = null) {
        super(width, height, options);

        this.isWebGL3DRenderTarget = true;
        this.depth = depth;
        this.texture = new Data3DTexture(null, width, height, depth);
        this.texture.isRenderTargetTexture = true;
    }
}

Lib.define('three.renderers.WebGL3DRenderTarget', WebGL3DRenderTarget);