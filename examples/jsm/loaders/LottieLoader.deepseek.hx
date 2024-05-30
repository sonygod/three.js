import three.FileLoader;
import three.Loader;
import three.CanvasTexture;
import three.NearestFilter;
import three.SRGBColorSpace;

import js.Lib.lottie;

class LottieLoader extends Loader {

	public function setQuality(value:Float):Void {
		this._quality = value;
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):CanvasTexture {
		var quality = this._quality ? this._quality : 1;

		var texture = new CanvasTexture();
		texture.minFilter = NearestFilter;
		texture.colorSpace = SRGBColorSpace;

		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setWithCredentials(this.withCredentials);

		loader.load(url, function(text:String) {
			var data = haxe.Json.parse(text);

			var container = js.Browser.document.createElement('div');
			container.style.width = data.w + 'px';
			container.style.height = data.h + 'px';
			js.Browser.document.body.appendChild(container);

			var animation = lottie.loadAnimation({
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