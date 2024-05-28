package three.renderers;

import three.textures.Data3DTexture;

class WebGL3DRenderTarget extends WebGLRenderTarget {
    public var isWebGL3DRenderTarget:Bool = true;
    public var depth:Int;

    public function new(width:Int = 1, height:Int = 1, depth:Int = 1, options:Dynamic = {}) {
        super(width, height, options);

        this.depth = depth;

        texture = new Data3DTexture(null, width, height, depth);
        texture.isRenderTargetTexture = true;
    }
}