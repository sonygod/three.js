package;

import haxe.extern.EitherType;

import js.html.webgl.RenderingContext;

class WebGLRenderTarget extends RenderTarget {

	public var isWebGLRenderTarget(default, null): Bool = true;

	public function new(width:Int = 1, height:Int = 1, options:Dynamic = {}) {
		super(width, height, options);
	}

}