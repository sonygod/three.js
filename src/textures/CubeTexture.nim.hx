import Texture from './Texture.hx';
import CubeReflectionMapping from '../constants.hx';

class CubeTexture extends Texture {
    public var isCubeTexture:Bool = true;
    public var flipY:Bool = false;

    public function new(images:Array<Dynamic>, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, format:Int, type:Int, anisotropy:Float, colorSpace:Int) {
        images = images != null ? images : [];
        mapping = mapping != null ? mapping : CubeReflectionMapping;

        super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);
    }

    public function get images():Array<Dynamic> {
        return this.image;
    }

    public function set images(value:Array<Dynamic>) {
        this.image = value;
    }
}

export default CubeTexture;