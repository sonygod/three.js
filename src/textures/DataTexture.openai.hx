package three.js.src.textures;

import three.js.Texture;
import three.js.constants.NearestFilter;

class DataTexture extends Texture {
    public var isDataTexture:Bool = true;
    public var image:{ data:Array<Int>, width:Int, height:Int };

    public function new(?data:Array<Int>, width:Int = 1, height:Int = 1, format:Int, type:Int, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Int = NearestFilter, minFilter:Int = NearestFilter, anisotropy:Float, colorSpace:Int) {
        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);
        this.image = { data: data, width: width, height: height };
        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;
    }
}