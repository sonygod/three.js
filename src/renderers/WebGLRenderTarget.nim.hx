import three.core.RenderTarget;

class WebGLRenderTarget extends RenderTarget {

    public function new(width:Int = 1, height:Int = 1, options:Dynamic = {}) {
        super(width, height, options);

        this.isWebGLRenderTarget = true;
    }

}

export haxe.macro.Expr.createClass(WebGLRenderTarget, {});