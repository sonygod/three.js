import three.textures.Texture;
import three.constants.TextureConstants;

class FramebufferTexture extends Texture {

	public function new(width:Int, height:Int) {
		super({ width: width, height: height });

		this.isFramebufferTexture = true;

		this.magFilter = TextureConstants.NearestFilter;
		this.minFilter = TextureConstants.NearestFilter;

		this.generateMipmaps = false;

		this.needsUpdate = true;
	}

}