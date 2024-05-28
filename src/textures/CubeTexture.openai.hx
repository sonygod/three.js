package three.js.src.textures;

import three.js.src.Texture;
import three.js.src.constants.CubeReflectionMapping;

class CubeTexture extends Texture {

	public var isCubeTexture:Bool = true;
	public var flipY:Bool = false;

	public function new(images:Array<Texture>, ?mapping:Int = CubeReflectionMapping, ?wrapS:Int, ?wrapT:Int, ?magFilter:Int, ?minFilter:Int, ?format:Int, ?type:Int, ?anisotropy:Float, ?colorSpace:Int) {
		if (images == null) images = [];
		if (mapping == null) mapping = CubeReflectionMapping;
		super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);
	}

	private var _images:Array<Texture>;

	public function get_images():Array<Texture> {
		return _images;
	}

	public function set_images(value:Array<Texture>):Void {
		_images = value;
	}
}