import three.constants.CubeReflectionMapping;
import three.textures.CompressedTexture;

class CompressedCubeTexture extends CompressedTexture {

    public function new(images:Array<Dynamic>, format:Int, type:Int) {
        super(null, images[0].width, images[0].height, format, type, CubeReflectionMapping);
        this.isCompressedCubeTexture = true;
        this.isCubeTexture = true;
        this.image = images;
    }

}