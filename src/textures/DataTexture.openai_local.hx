package three.textures;

import three.textures.Texture;
import three.constants.NearestFilter;

class DataTexture extends Texture {

    public var isDataTexture:Bool;
    public var image:{ data:Dynamic, width:Int, height:Int };
    public var generateMipmaps:Bool;
    public var flipY:Bool;
    public var unpackAlignment:Int;

    public function new(
        data:Dynamic = null, 
        width:Int = 1, 
        height:Int = 1, 
        format:Dynamic = null, 
        type:Dynamic = null, 
        mapping:Dynamic = null, 
        wrapS:Dynamic = null, 
        wrapT:Dynamic = null, 
        magFilter:Dynamic = NearestFilter, 
        minFilter:Dynamic = NearestFilter, 
        anisotropy:Dynamic = null, 
        colorSpace:Dynamic = null
    ) {
        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);
        
        this.isDataTexture = true;
        this.image = { data: data, width: width, height: height };
        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;
    }

}