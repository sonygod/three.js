package;

import js.openfl.Texture;
import js.openfl.constants.NearestFilter;

class FramebufferTexture extends Texture {
	public var isFramebufferTexture:Bool;
	public var magFilter:NearestFilter;
	public var minFilter:NearestFilter;
	public var generateMipmaps:Bool;
	public var needsUpdate:Bool;

	public function new(width:Int, height:Int) {
		super({ width: width, height: height });

		isFramebufferTexture = true;
		magFilter = NearestFilter.Nearest;
		minFilter = NearestFilter.Nearest;
		generateMipmaps = false;
		needsUpdate = true;
	}
}

@:jsRequire("js/FramebufferTexture.hx")
extern function framebufferTexture_js(width:Int, height:Int):FramebufferTexture;

@:jsRequire("js/FramebufferTexture.hx")
extern function framebufferTexture_js(texture:FramebufferTexture):Void;