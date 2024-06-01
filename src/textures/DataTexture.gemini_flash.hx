package ;

import Constants.Constants;

class DataTexture extends Texture {

    public var isDataTexture(default, null):Bool = true;

    public function new(data:Dynamic = null, width:Int = 1, height:Int = 1, 
        ?format:Int, ?type:Int, ?mapping:Int, ?wrapS:Int, ?wrapT:Int, 
        ?magFilter:Int = Constants.NearestFilter, ?minFilter:Int = Constants.NearestFilter, 
        ?anisotropy:Int, ?colorSpace:Int) 
    {
        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);

        this.image = { data: data, width: width, height: height };

        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;
    }

}