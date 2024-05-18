package three.textures;

import three.Texture;
import three.constants.CubeReflectionMapping;

class CubeTexture extends Texture {

    public var isCubeTexture:Bool = true;
    public var flipY:Bool = false;

    public function new(images:Array<Dynamic>, mapping:Int = CubeReflectionMapping, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, format:Int, type:Int, anisotropy:Float, colorSpace:Int) {
        if (images == null) images = [];
        if (mapping == null) mapping = CubeReflectionMapping;
        super(images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace);
    }

    private var _image:Array<Dynamic>;

    public function get_images():Array<Dynamic> {
        return _image;
    }

    public function set_images(value:Array<Dynamic>):Void {
        _image = value;
    }
}