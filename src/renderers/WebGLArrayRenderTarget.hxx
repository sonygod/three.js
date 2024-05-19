package three.js.src.renderers;

import three.js.src.textures.DataArrayTexture;
import three.js.src.renderers.WebGLRenderTarget;

class WebGLArrayRenderTarget extends WebGLRenderTarget {

    public function new(width:Int = 1, height:Int = 1, depth:Int = 1, options:Dynamic = {}) {
        super(width, height, options);

        this.isWebGLArrayRenderTarget = true;

        this.depth = depth;

        this.texture = new DataArrayTexture(null, width, height, depth);

        this.texture.isRenderTargetTexture = true;
    }

    public var isWebGLArrayRenderTarget:Bool;
    public var depth:Int;
    public var texture:DataArrayTexture;
}