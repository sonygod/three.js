import three.js.src.loaders.ImageLoader;
import three.js.src.textures.Texture;
import three.js.src.loaders.Loader;

class TextureLoader extends Loader {

	public function new(manager:Dynamic) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Texture {
		var texture = new Texture();
		var loader = new ImageLoader(this.manager);
		loader.setCrossOrigin(this.crossOrigin);
		loader.setPath(this.path);

		loader.load(url, function(image) {
			texture.image = image;
			texture.needsUpdate = true;

			if (onLoad != null) {
				onLoad(texture);
			}
		}, onProgress, onError);

		return texture;
	}
}