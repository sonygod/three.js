package three.js.src.textures;

import three.js.src.textures.Texture;

class CompressedTexture extends Texture {
    public var isCompressedTexture:Bool = true;

    public function new(mipmaps:Array<Dynamic>, width:Int, height:Int, format:Int, type:Int, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, anisotropy:Float, colorSpace:Int) {
        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);

        this.image = { width: width, height: height };
        this.mipmaps = mipmaps;

        this.flipY = false;
        this.generateMipmaps = false;
    }
}