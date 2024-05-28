package three.renderers;

import three.textures.DataArrayTexture;
import three.renderers.WebGLRenderTarget;

class WebGLArrayRenderTarget extends WebGLRenderTarget {
    public var isWebGLArrayRenderTarget:Bool = true;
    public var depth:Int;

    public function new(width:Int = 1, height:Int = 1, depth:Int = 1, options:Dynamic = {}) {
        super(width, height, options);
        this.depth = depth;
        this.texture = new DataArrayTexture(null, width, height, depth);
        this.texture.isRenderTargetTexture = true;
    }
}