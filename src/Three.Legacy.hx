package three;

import three.renderers.WebGLRenderTarget;

@:depreacted("THREE.WebGLMultipleRenderTargets has been deprecated and will be removed in r172. Use THREE.WebGLRenderTarget and set the \"count\" parameter to enable MRT.")
class WebGLMultipleRenderTargets extends WebGLRenderTarget {
    public var isWebGLMultipleRenderTargets:Bool = true;

    public function new(width:Int = 1, height:Int = 1, count:Int = 1, options:Dynamic = {}) {
        trace("THREE.WebGLMultipleRenderTargets has been deprecated and will be removed in r172. Use THREE.WebGLRenderTarget and set the \"count\" parameter to enable MRT.");
        super(width, height, { ...options, count: count });
    }

    public var texture(get, never):Array<Texture>;

    private function get_texture():Array<Texture> {
        return textures;
    }
}