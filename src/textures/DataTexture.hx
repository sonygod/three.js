package three.textures;

import three.js Texture;
import three.constants.NearestFilter;

class DataTexture extends Texture {

    public var isDataTexture:Bool = true;

    public var image:{ data:Dynamic, width:Int, height:Int };

    public function new(?data:Dynamic, width:Int = 1, height:Int = 1, format:Dynamic, type:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic = NearestFilter, minFilter:Dynamic = NearestFilter, anisotropy:Dynamic, colorSpace:Dynamic) {
        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);

        this.image = { data: data, width: width, height: height };

        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;
    }
}