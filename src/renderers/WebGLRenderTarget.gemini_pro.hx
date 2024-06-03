import core.RenderTarget;

class WebGLRenderTarget extends RenderTarget {

	public var isWebGLRenderTarget:Bool = true;

	public function new(width:Int = 1, height:Int = 1, options:Dynamic = {}) {
		super(width, height, options);
	}

}

class WebGLRenderTarget {
	static public var  WebGLRenderTarget:WebGLRenderTarget;
}