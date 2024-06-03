import ImageLoader from "./ImageLoader";
import Texture from "../textures/Texture";
import Loader from "./Loader";

class TextureLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Texture->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Texture {
		var texture = new Texture();
		var loader = new ImageLoader(this.manager);
		loader.setCrossOrigin(this.crossOrigin);
		loader.setPath(this.path);

		loader.load(url, function(image:Dynamic) {
			texture.image = image;
			texture.needsUpdate = true;

			if (onLoad != null) {
				onLoad(texture);
			}
		}, onProgress, onError);

		return texture;
	}
}

export class TextureLoader {
}