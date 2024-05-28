class CompressedTexture extends Texture {
	public var isCompressedTexture:Bool = true;
	public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, format:String, type:Int, mapping:String, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, anisotropy:Int, colorSpace:Int) {
		super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);
		image = { width: width, height: height };
		this.mipmaps = mipmaps;
		flipY = false;
		generateMipmaps = false;
	}
}