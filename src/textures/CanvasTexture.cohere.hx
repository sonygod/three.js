import js.Browser.HTMLCanvasElement;
import js.Browser.WebGLRenderingContext;

class CanvasTexture extends Texture {
    public var isCanvasTexture:Bool;
    public var needsUpdate:Bool;

    public function new(canvas:HTMLCanvasElement, mapping:Dynamic, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, format:Int, type:Int, anisotropy:Int) {
        super(canvas, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
        isCanvasTexture = true;
        needsUpdate = true;
    }
}