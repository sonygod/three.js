package three.js.src.textures;

import three.js.src.Texture;
import three.js.src.constants.CubeReflectionMapping;

class CubeTexture extends Texture {
	
	public var isCubeTexture:Bool = true;
	public var flipY:Bool = false;

	public function new(images:Array<Dynamic> = [], mapping:Int = CubeReflectionMapping, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, format:Int, type:Int, anisotropy:Int, colorSpace:Int) {
		images = if (images != null) images else [];
		mapping = if (mapping != null) mapping else CubeReflectionMapping;
		super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);
	}

	private var _images:Array<Dynamic>;

	public var images(get, set):Array<Dynamic>;

	function get_images():Array<Dynamic> {
		return _images;
	}

	function set_images(value:Array<Dynamic>):Array<Dynamic> {
		return _images = value;
	}
}