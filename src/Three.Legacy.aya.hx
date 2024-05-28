package ;

class WebGLMultipleRenderTargets extends WebGLRenderTarget {

    public function new(width:Int, height:Int, count:Int, options:Object) {
        super(width, height, { ...options, count: count });
        this.isWebGLMultipleRenderTargets = true;
    }

    public function get texture():Array<Dynamic> {
        return this.textures;
    }

}