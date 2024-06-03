import three.textures.Texture;
import three.constants.CubeReflectionMapping;

class CubeTexture extends Texture {

    public function new(images:Array<Dynamic>=null, mapping:Int=CubeReflectionMapping, wrapS:Int=null, wrapT:Int=null, magFilter:Int=null, minFilter:Int=null, format:Int=null, type:Int=null, anisotropy:Int=null, colorSpace:Int=null) {
        if (images == null) images = [];
        if (mapping == null) mapping = CubeReflectionMapping;

        super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);

        this.isCubeTexture = true;
        this.flipY = false;
    }

    public function get images():Array<Dynamic> {
        return this.image;
    }

    public function set images(value:Array<Dynamic>) {
        this.image = value;
    }
}