import three.textures.Texture;

class CompressedTexture extends Texture {

    public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, format:Int, type:Int, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, anisotropy:Int, colorSpace:Int) {
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
    }
}