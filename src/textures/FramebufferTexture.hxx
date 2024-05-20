import three.js.src.textures.Texture;
import three.js.src.constants.NearestFilter;

class FramebufferTexture extends Texture {

	public function new(width:Int, height:Int) {
		super({width:width, height:height});

		this.isFramebufferTexture = true;

		this.magFilter = NearestFilter;
		this.minFilter = NearestFilter;

		this.generateMipmaps = false;

		this.needsUpdate = true;
	}
}