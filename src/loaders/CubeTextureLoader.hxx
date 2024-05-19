import three.js.src.loaders.ImageLoader;
import three.js.src.textures.CubeTexture;
import three.js.src.loaders.Loader;
import three.js.src.constants.SRGBColorSpace;

class CubeTextureLoader extends Loader {

	public function new(manager:Dynamic) {
		super(manager);
	}

	public function load(urls:Array<String>, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):CubeTexture {
		var texture = new CubeTexture();
		texture.colorSpace = SRGBColorSpace;

		var loader = new ImageLoader(this.manager);
		loader.setCrossOrigin(this.crossOrigin);
		loader.setPath(this.path);

		var loaded = 0;

		function loadTexture(i:Int) {
			loader.load(urls[i], function(image) {
				texture.images[i] = image;
				loaded++;
				if (loaded == 6) {
					texture.needsUpdate = true;
					if (onLoad != null) onLoad(texture);
				}
			}, null, onError);
		}

		for (i in 0...urls.length) {
			loadTexture(i);
		}

		return texture;
	}
}