package three.textures;

import three.src.textures.Texture;

class CanvasTexture extends Texture {
    
    public var isCanvasTexture:Bool = true;
    public var needsUpdate:Bool = true;

    public function new(canvas:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic, minFilter:Dynamic, format:Dynamic, type:Dynamic, anisotropy:Dynamic) {
        super(canvas, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
    }
}