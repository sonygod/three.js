import js.Browser.console;
import js.Lib.WebGLRenderTarget;

class WebGLMultipleRenderTargets extends WebGLRenderTarget { // @deprecated, r162

	public function new(width:Int = 1, height:Int = 1, count:Int = 1, options:Dynamic = {}) {

		console.warn('THREE.WebGLMultipleRenderTargets has been deprecated and will be removed in r172. Use THREE.WebGLRenderTarget and set the "count" parameter to enable MRT.');

		options.count = count;
		super(width, height, options);

		this.isWebGLMultipleRenderTargets = true;

	}

	public function get_texture():Dynamic {

		return this.textures;

	}

}