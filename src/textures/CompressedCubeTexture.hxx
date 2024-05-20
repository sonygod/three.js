package three.js.src.textures;

import three.js.src.constants.CubeReflectionMapping;
import three.js.src.textures.CompressedTexture;

class CompressedCubeTexture extends CompressedTexture {

    public function new(images:Array<Dynamic>, format:String, type:String) {
        super(null, images[0].width, images[0].height, format, type, CubeReflectionMapping);

        this.isCompressedCubeTexture = true;
        this.isCubeTexture = true;

        this.image = images;
    }

}