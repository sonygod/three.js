import three.renderers.WebGLRenderTarget;

@:deprecated("r162")
class WebGLMultipleRenderTargets extends WebGLRenderTarget {

	public function new(width:Int = 1, height:Int = 1, count:Int = 1, options:Dynamic = {}) {
		console.warn("THREE.WebGLMultipleRenderTargets has been deprecated and will be removed in r172. Use THREE.WebGLRenderTarget and set the 'count' parameter to enable MRT.");
		super(width, height, { count __set: function(v:Int) this.count = v; }.bind(options));
		this.isWebGLMultipleRenderTargets = true;
	}

	public function get_texture():Array<WebGLRenderTarget> {
		return this.textures;
	}

}