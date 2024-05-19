import three.js.src.core.RenderTarget;

class WebGLRenderTarget extends RenderTarget {

	public function new(width:Float = 1, height:Float = 1, options:Dynamic = {}) {
		super(width, height, options);
		this.isWebGLRenderTarget = true;
	}

}

typedef WebGLRenderTarget_three_js_src_renderers_WebGLRenderTarget = WebGLRenderTarget;