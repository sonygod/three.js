import three.js.examples.jsm.loaders.FileLoader;
import three.js.examples.jsm.loaders.Loader;
import three.js.examples.jsm.textures.CanvasTexture;
import three.js.examples.jsm.constants.NearestFilter;
import three.js.examples.jsm.constants.SRGBColorSpace;

import lottie.Lottie;

class LottieLoader extends Loader {

	private var _quality:Float;

	public function setQuality(value:Float) {
		this._quality = value;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):CanvasTexture {
		var quality:Float = this._quality != null ? this._quality : 1;

		var texture:CanvasTexture = new CanvasTexture();
		texture.minFilter = NearestFilter;
		texture.colorSpace = SRGBColorSpace;

		var loader:FileLoader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setWithCredentials(this.withCredentials);

		loader.load(url, function(text:String) {
			var data:Dynamic = haxe.Json.parse(text);

			var container:js.html.Div = js.Browser.document.createElement("div");
			container.style.width = data.w + "px";
			container.style.height = data.h + "px";
			js.Browser.document.body.appendChild(container);

			var animation:Lottie.Animation = Lottie.loadAnimation({
				container: container,
				animType: 'canvas',
				loop: true,
				autoplay: true,
				animationData: data,
				rendererSettings: { dpr: quality }
			});

			texture.animation = animation;
			texture.image = animation.container;

			animation.addEventListener('enterFrame', function() {
				texture.needsUpdate = true;
			});

			container.style.display = 'none';

			if (onLoad != null) {
				onLoad(texture);
			}
		}, onProgress, onError);

		return texture;
	}
}