import kha.Image;
import kha.graphics4.TextureFormat;
import kha.graphics4.TextureType;
import kha.graphics4.MipMapMode;

class CompressedTexture extends Texture {

	public function new(mipmaps:Array<Image>, width:Int, height:Int, format:TextureFormat, type:TextureType, mapping:TextureMapping, wrapS:TextureWrapping, wrapT:TextureWrapping, magFilter:TextureFilter, minFilter:TextureFilter, anisotropy:Int, colorSpace:ColorSpace) {

		super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);

		this.isCompressedTexture = true;

		this.image = { width: width, height: height };
		this.mipmaps = mipmaps;

		// no flipping for cube textures
		// (also flipping doesn't work for compressed textures )
		this.flipY = false;

		// can't generate mipmaps for compressed textures
		// mips must be embedded in DDS files
		this.generateMipmaps = false;
		this.mipmapMode = MipMapMode.NoMipMaps;
	}

}