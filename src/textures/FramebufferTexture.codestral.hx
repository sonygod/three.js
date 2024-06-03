import three.textures.Texture;
import three.constants.NearestFilter;

class FramebufferTexture extends Texture {

    public function new(width: Int, height: Int) {
        super(new { width: width, height: height });

        this.isFramebufferTexture = true;

        this.magFilter = NearestFilter;
        this.minFilter = NearestFilter;

        this.generateMipmaps = false;

        this.needsUpdate = true;
    }
}

export FramebufferTexture;