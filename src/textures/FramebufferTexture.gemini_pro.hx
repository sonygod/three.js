import Texture from "./Texture";
import NearestFilter from "../constants";

class FramebufferTexture extends Texture {

	public function new(width:Int, height:Int) {
		super({width: width, height: height});

		this.isFramebufferTexture = true;

		this.magFilter = NearestFilter;
		this.minFilter = NearestFilter;

		this.generateMipmaps = false;

		this.needsUpdate = true;
	}

}

export class FramebufferTexture {
}