import three.renderers.WebGLRenderTarget;

class WebGLMultipleRenderTargets extends WebGLRenderTarget {
    public function new(width:Int = 1, height:Int = 1, count:Int = 1, options:Dynamic = {}) {
        Sys.warning("THREE.WebGLMultipleRenderTargets has been deprecated and will be removed in r172. Use THREE.WebGLRenderTarget and set the \"count\" parameter to enable MRT.");
        super(width, height, untyped {
            ...options,
            count: count
        });
        this.isWebGLMultipleRenderTargets = true;
    }

    public var texture:Array<Dynamic>
        get
            return this.textures;
        end;

    public var isWebGLMultipleRenderTargets:Bool;
}