import three.renderers.WebGLRenderTarget;

class WebGLMultipleRenderTargets extends WebGLRenderTarget {

    public function new(width:Int = 1, height:Int = 1, count:Int = 1, options:Dynamic = null) {
        trace('THREE.WebGLMultipleRenderTargets has been deprecated and will be removed in r172. Use THREE.WebGLRenderTarget and set the "count" parameter to enable MRT.');

        if (options == null) options = {};
        options.count = count;

        super(width, height, options);

        this.isWebGLMultipleRenderTargets = true;
    }

    public function get_texture():Array<Dynamic> {
        return this.textures;
    }

}