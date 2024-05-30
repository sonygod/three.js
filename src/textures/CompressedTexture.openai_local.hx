import threejs.textures.Texture;

class CompressedTexture extends Texture {

	public var isCompressedTexture:Bool;
	public var mipmaps:Array<Dynamic>;
	public var image:Dynamic;
	public var flipY:Bool;
	public var generateMipmaps:Bool;

	public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, format:Dynamic, type:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic, minFilter:Dynamic, anisotropy:Float, colorSpace:Dynamic) {

		super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);

		this.isCompressedTexture = true;

		this.image = { width: width, height: height };
		this.mipmaps = mipmaps;

		// no flipping for cube textures
		// (also flipping doesn't work for compressed textures)

		this.flipY = false;

		// can't generate mipmaps for compressed textures
		// mips must be embedded in DDS files

		this.generateMipmaps = false;

	}

}