import js.html.Canvas;
import three.js.src.textures.Texture;

class CanvasTexture extends Texture {

    public function new(canvas:Canvas, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, format:Int, type:Int, anisotropy:Int) {
        super(canvas, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

        this.isCanvasTexture = true;

        this.needsUpdate = true;
    }

}