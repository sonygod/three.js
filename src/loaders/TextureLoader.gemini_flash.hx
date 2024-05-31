import three.loaders.ImageLoader;
import three.textures.Texture;
import three.loaders.Loader;

class TextureLoader extends Loader {

	public function new(manager : Loader) {
		super(manager);
	}

	public function load(url : String, onLoad : Texture->Void = null, onProgress : Float->Void = null, onError : Dynamic->Void = null) : Texture {
		var texture = new Texture();
		var loader = new ImageLoader(this.manager);
		loader.setCrossOrigin(this.crossOrigin);
		loader.setPath(this.path);

		loader.load(url, function(image : Image) {
			texture.image = image;
			texture.needsUpdate = true;
			if (onLoad != null) {
				onLoad(texture);
			}
		}, onProgress, onError);

		return texture;
	}
}