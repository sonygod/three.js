package three.src.textures;

import three.src.textures.Texture;
import three.src.constants.NearestFilter;

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