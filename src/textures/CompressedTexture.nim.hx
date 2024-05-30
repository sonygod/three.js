import three.js.src.textures.Texture;

class CompressedTexture extends Texture {

    public var isCompressedTexture:Bool = true;
    public var image:Dynamic;
    public var mipmaps:Dynamic;
    public var flipY:Bool = false;
    public var generateMipmaps:Bool = false;

    public function new(mipmaps:Dynamic, width:Int, height:Int, format:Dynamic, type:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic, minFilter:Dynamic, anisotropy:Dynamic, colorSpace:Dynamic) {

        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);

        this.image = { width: width, height: height };
        this.mipmaps = mipmaps;

    }

}

export type CompressedTexture = three.js.src.textures.CompressedTexture;