import Texture from "./Texture";

class CanvasTexture extends Texture {

    public var isCanvasTexture:Bool;
    public var needsUpdate:Bool;

    public function new(canvas:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic, minFilter:Dynamic, format:Dynamic, type:Dynamic, anisotropy:Dynamic) {
        super(canvas, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
        this.isCanvasTexture = true;
        this.needsUpdate = true;
    }

}

class CanvasTexture {
    public static function new(canvas:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic, minFilter:Dynamic, format:Dynamic, type:Dynamic, anisotropy:Dynamic) : CanvasTexture {
        return new CanvasTexture(canvas, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
    }
}