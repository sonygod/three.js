import js.three.loaders.FileLoader;
import js.three.textures.CanvasTexture;
import js.three.textures.NearestFilter;
import js.three.textures.SRGBColorSpace;

import Lottie from '../libs/lottie_canvas.module.js';

class LottieLoader extends js.three.Loader {
	public var _quality:Float;

	public function setQuality(value:Float) {
		_quality = value;
	}

	override public function load(url:String, onLoad:Void->Void, onProgress:Float->Void, onError:Dynamic->Void):CanvasTexture {
		var quality = _quality ?? 1.0;
		var texture = new CanvasTexture();
		texture.minFilter = NearestFilter;
		texture.colorSpace = SRGBColorSpace;

		var loader = new FileLoader(manager);
		loader.path = path;
		loader.withCredentials = withCredentials;

		loader.load(url, function(text:String) {
			var data = js.Json.parse(text);

			// lottie uses container.offsetWidth and offsetHeight
			// to define width/height
			var container = js.Browser.document.createElement('div');
			container.style.width = data.w + 'px';
			container.style.height = data.h + 'px';
			js.Browser.document.body.appendChild(container);

			var animation = Lottie.loadAnimation({
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
				onLoad();
			}
		}, onProgress, onError);

		return texture;
	}
}

class Export {
	public static function LottieLoader() {
		return LottieLoader;
	}
}