import three.loaders.FileLoader;
import three.loaders.Loader;
import three.textures.CanvasTexture;
import three.constants.Filters;
import three.constants.ColorSpace;

class LottieLoader extends Loader {

	public var _quality:Float;

	public function setQuality(value:Float):Void {
		this._quality = value;
	}

	public function load(url:String, onLoad:CanvasTexture->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):CanvasTexture {

		var quality = _quality != null ? _quality : 1;

		var texture = new CanvasTexture();
		texture.minFilter = Filters.NearestFilter;
		texture.colorSpace = ColorSpace.SRGBColorSpace;

		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setWithCredentials(this.withCredentials);

		loader.load(url, function(text:String) {

			var data = haxe.Json.parse(text);

			// lottie uses container.offetWidth and offsetHeight
			// to define width/height

			var container = js.html.document.createElement("div");
			container.style.width = data.w + "px";
			container.style.height = data.h + "px";
			js.html.document.body.appendChild(container);

			var animation = lottie.loadAnimation({
				container: container,
				animType: "canvas",
				loop: true,
				autoplay: true,
				animationData: data,
				rendererSettings: { dpr: quality }
			});

			texture.animation = animation;
			texture.image = animation.container;

			animation.addEventListener("enterFrame", function() {

				texture.needsUpdate = true;

			});

			container.style.display = "none";

			if (onLoad != null) {

				onLoad(texture);

			}

		}, onProgress, onError);

		return texture;

	}

}