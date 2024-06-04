import Texture from "./Texture";
import CubeReflectionMapping from "../constants";

class CubeTexture extends Texture {

    public var images:Array<Dynamic>;
    public var isCubeTexture:Bool = true;
    public var flipY:Bool = false;

    public function new(images:Array<Dynamic> = [], mapping:Int = CubeReflectionMapping,
                      wrapS:Int = 0, wrapT:Int = 0, magFilter:Int = 0, minFilter:Int = 0, format:Int = 0,
                      type:Int = 0, anisotropy:Float = 0, colorSpace:String = null) {

        super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);

        this.images = images;
    }
}

export default CubeTexture;