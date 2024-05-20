import Texture from './Texture.js';
import CubeReflectionMapping from '../constants.js';

class CubeTexture extends Texture {

	public function new(images:Array<Dynamic> = [], mapping:Dynamic = CubeReflectionMapping, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic, minFilter:Dynamic, format:Dynamic, type:Dynamic, anisotropy:Dynamic, colorSpace:Dynamic) {

		super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);

		this.isCubeTexture = true;

		this.flipY = false;

	}

	public function get_images():Dynamic {

		return this.image;

	}

	public function set_images(value:Dynamic):Void {

		this.image = value;

	}

}

typedef CubeTexture_hx = CubeTexture;