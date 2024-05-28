package three.src.textures;

import three.src.Texture;
import three.src.constants.Clamping;
import three.src.constants.Filter;

class Data3DTexture extends Texture {
    public var isData3DTexture:Bool;

    public function new(?data:Dynamic, width:Int = 1, height:Int = 1, depth:Int = 1) {
        super(null);

        this.isData3DTexture = true;

        this.image = { data: data, width: width, height: height, depth: depth };

        this.magFilter = Filter.NearestFilter;
        this.minFilter = Filter.NearestFilter;

        this.wrapR = Clamping.ClampToEdgeWrapping;

        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;
    }
}