package three.js.src.textures;

import three.js.src.textures.Texture;
import three.js.src.constants.NearestFilter;

class FramebufferTexture extends Texture {
    public var isFramebufferTexture:Bool = true;

    public function new(width:Int, height:Int) {
        super({ width: width, height: height });

        magFilter = NearestFilter.NEAREST;
        minFilter = NearestFilter.NEAREST;

        generateMipmaps = false;

        needsUpdate = true;
    }
}