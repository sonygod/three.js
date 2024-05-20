import three.textures.Texture;
import three.constants.ClampToEdgeWrapping;
import three.constants.NearestFilter;

class Data3DTexture extends Texture {

    public function new(data:Dynamic = null, width:Int = 1, height:Int = 1, depth:Int = 1) {
        super(null);

        this.isData3DTexture = true;

        this.image = { data: data, width: width, height: height, depth: depth };

        this.magFilter = NearestFilter;
        this.minFilter = NearestFilter;

        this.wrapR = ClampToEdgeWrapping;

        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;
    }

}