package three.textures;

import three.textures.Texture;

class CompressedTexture extends Texture {
    
    public var isCompressedTexture:Bool = false;
    public var image:{ width:Int, height:Int };
    public var mipmaps:Array<Dynamic>;
    public var flipY:Bool = false;
    public var generateMipmaps:Bool = false;

    public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, format:Dynamic, type:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic, minFilter:Dynamic, anisotropy:Dynamic, colorSpace:Dynamic) {
        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);
        isCompressedTexture = true;
        image = { width: width, height: height };
        this.mipmaps = mipmaps;
        flipY = false;
        generateMipmaps = false;
    }
}