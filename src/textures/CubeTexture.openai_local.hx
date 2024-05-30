import three.textures.Texture;
import three.constants.CubeReflectionMapping;

class CubeTexture extends Texture {

    public var isCubeTexture:Bool;
    public var flipY:Bool;

    public function new( ?images:Array<Dynamic>, ?mapping:Dynamic, ?wrapS:Dynamic, ?wrapT:Dynamic, 
                         ?magFilter:Dynamic, ?minFilter:Dynamic, ?format:Dynamic, ?type:Dynamic, 
                         ?anisotropy:Dynamic, ?colorSpace:Dynamic ) {

        images = (images != null) ? images : [];
        mapping = (mapping != null) ? mapping : CubeReflectionMapping;

        super( images, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy, colorSpace );

        this.isCubeTexture = true;
        this.flipY = false;
    }

    public function get_images():Array<Dynamic> {
        return this.image;
    }

    public function set_images( value:Array<Dynamic> ):Array<Dynamic> {
        this.image = value;
        return value;
    }

}