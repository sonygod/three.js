package ;

import three.textures.Texture;
import three.constants.CubeReflectionMapping;

class CubeTexture extends Texture {

	public function new( images : Array<Dynamic> = null, mapping : Int = 0, wrapS : Int = 0, wrapT : Int = 0, magFilter : Int = 0, minFilter : Int = 0, format : Int = 0, type : Int = 0, anisotropy : Int = 0, colorSpace : Int = 0 ) {

		if (images == null) images = [];
		if (mapping == 0) mapping = CubeReflectionMapping;

		super( images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace );

		this.isCubeTexture = true;

		this.flipY = false;

	}

	public var images(get, set) : Array<Dynamic>;

	inline function get_images() : Array<Dynamic> {

		return this.image;

	}

	inline function set_images( value : Array<Dynamic> ) : Array<Dynamic> {

		return this.image = value;

	}

}