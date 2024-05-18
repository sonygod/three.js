package three.textures;

import three.src.textures.Texture;

class Data3DTexture extends Texture {

    public var isData3DTexture:Bool = true;

    public function new(?data:Dynamic, width:Int = 1, height:Int = 1, depth:Int = 1) {
        super(null);

        this.image = { data: data, width: width, height: height, depth: depth };

        this.magFilter = NearestFilter;
        this.minFilter = NearestFilter;

        this.wrapR = ClampToEdgeWrapping;

        this.generateMipmaps = false;
        this.flipY = false;
        this.unpackAlignment = 1;
    }
}