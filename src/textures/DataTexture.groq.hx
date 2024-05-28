package three.js.src.textures;

import three.js.src.Texture;
import three.js.src.constants.NearestFilter;

class DataTexture extends Texture {
    
    public var isDataTexture:Bool = true;
    public var image:{ data:Dynamic, width:Int, height:Int };

    public function new(?data:Dynamic, width:Int = 1, height:Int = 1, format:Dynamic, type:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic = NearestFilter, minFilter:Dynamic = NearestFilter, anisotropy:Dynamic, colorSpace:Dynamic) {
        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);
        
        this.image = { data: data, width: width, height: height };
        
        generateMipmaps = false;
        flipY = false;
        unpackAlignment = 1;
    }
}