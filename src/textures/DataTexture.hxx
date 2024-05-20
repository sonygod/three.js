import three.js.src.textures.Texture;
import three.js.src.constants.NearestFilter;

class DataTexture extends Texture {

	public function new(data:Dynamic = null, width:Int = 1, height:Int = 1, format:Dynamic, type:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic = NearestFilter, minFilter:Dynamic = NearestFilter, anisotropy:Dynamic, colorSpace:Dynamic) {

		super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);

		this.isDataTexture = true;

		this.image = { data: data, width: width, height: height };

		this.generateMipmaps = false;
		this.flipY = false;
		this.unpackAlignment = 1;

	}

}