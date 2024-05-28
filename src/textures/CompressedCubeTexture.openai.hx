package three.js.src.textures;

import three.js.constants.CubeReflectionMapping;
import three.js.textures.CompressedTexture;

class CompressedCubeTexture extends CompressedTexture {

    public var isCompressedCubeTexture:Bool = true;
    public var isCubeTexture:Bool = true;

    public var image:Array<Dynamic>;

    public function new(images:Array<Dynamic>, format:Dynamic, type:Dynamic) {
        super(null, images[0].width, images[0].height, format, type, CubeReflectionMapping);
        this.image = images;
    }
}