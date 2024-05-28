package three.js.src.renderers;

import three.core.RenderTarget;

class WebGLRenderTarget extends RenderTarget {
    public var isWebGLRenderTarget:Bool;

    public function new(width:Int = 1, height:Int = 1, options:Dynamic = {}) {
        super(width, height, options);
        isWebGLRenderTarget = true;
    }
}