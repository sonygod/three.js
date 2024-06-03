import three.core.RenderTarget;

class WebGLRenderTarget extends RenderTarget {

    public function new(width:Int = 1, height:Int = 1, options:haxe.ds.StringMap<Dynamic> = new haxe.ds.StringMap()) {
        super(width, height, options);
        this.isWebGLRenderTarget = true;
    }
}