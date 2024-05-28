package openfl.display3D.textures;

import openfl.display3D.RenderTarget;

class WebGLRenderTarget extends RenderTarget {

	public var isWebGLRenderTarget:Bool;

	public function new(width:Int = 1, height:Int = 1, ?options:Dynamic) {
		super(width, height, options);
		this.isWebGLRenderTarget = true;
	}

}