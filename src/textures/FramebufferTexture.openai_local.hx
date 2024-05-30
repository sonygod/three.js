import three.textures.Texture;
import three.constants.NearestFilter;

class FramebufferTexture extends Texture {

    public var isFramebufferTexture:Bool;
    public var magFilter:Dynamic;
    public var minFilter:Dynamic;
    public var generateMipmaps:Bool;
    public var needsUpdate:Bool;

    public function new(width:Int, height:Int) {
        super({ width: width, height: height });

        this.isFramebufferTexture = true;

        this.magFilter = NearestFilter;
        this.minFilter = NearestFilter;

        this.generateMipmaps = false;

        this.needsUpdate = true;
    }

}