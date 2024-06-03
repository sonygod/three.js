import three.Texture;
import three.constants.NearestFilter;

class DataTexture extends Texture {

    public function new(data:Dynamic=null, width:Int=1, height:Int=1, format:Int, type:Int, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Int=NearestFilter, minFilter:Int=NearestFilter, anisotropy:Int=0, colorSpace:String="") {
        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);

        this.isDataTexture = true;

        this.image = { data: data, width: width, height: height };

        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;
    }
}

export { DataTexture };