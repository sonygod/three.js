package three.js.src.textures;

import three.js.src.textures.Texture;

class CompressedTexture extends Texture {

    public var isCompressedTexture:Bool = true;

    public var image:{ width:Int, height:Int };
    public var mipmaps:Array<Dynamic>;

    public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, format:Dynamic, type:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic, minFilter:Dynamic, anisotropy:Dynamic, colorSpace:Dynamic) {
        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);

        this.image = { width: width, height: height };
        this.mipmaps = mipmaps;

        this.flipY = false;

        this.generateMipmaps = false;
    }

}