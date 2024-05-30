package three.js;

import three.js.renderers.WebGLMultipleRenderTargets;

class WebGLMultipleRenderTargets {
  public function new(width:Int = 1, height:Int = 1, count:Int = 1, options:Dynamic = {}) {
    trace('THREE.WebGLMultipleRenderTargets has been deprecated and will be removed in r172. Use THREE.WebGLRenderTarget and set the "count" parameter to enable MRT.');
    new WebGLMultipleRenderTargets(width, height, {...options, count });
  }
}