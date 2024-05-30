import js.three.renderers.WebGLRenderTarget;

@:deprecated("THREE.WebGLMultipleRenderTargets has been deprecated and will be removed in r172. Use THREE.WebGLRenderTarget and set the \"count\" parameter to enable MRT.")
class WebGLMultipleRenderTargets extends WebGLRenderTarget {

  public function new(width:Int = 1, height:Int = 1, count:Int = 1, options:Dynamic = {}) {
    js.Lib.warn('THREE.WebGLMultipleRenderTargets has been deprecated and will be removed in r172. Use THREE.WebGLRenderTarget and set the "count" parameter to enable MRT.');
    super(width, height, options.copy().count = count);
    this.isWebGLMultipleRenderTargets = true;
  }

  public function get_texture():Array<WebGLRenderTarget> {
    return this.textures;
  }

}