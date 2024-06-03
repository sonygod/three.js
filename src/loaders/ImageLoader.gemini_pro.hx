import Cache from "./Cache";
import Loader from "./Loader";
import utils from "../utils";

class ImageLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Dynamic {
		if (this.path != null) url = this.path + url;
		url = this.manager.resolveURL(url);
		var scope = this;
		var cached = Cache.get(url);
		if (cached != null) {
			this.manager.itemStart(url);
			var delay = 0;
			if (onLoad != null) {
				delay = 0;
				onLoad(cached);
			}
			this.manager.itemEnd(url);
			return cached;
		}
		var image = utils.createElementNS("img");
		var onImageLoad = function():Void {
			removeEventListeners();
			Cache.add(url, this);
			if (onLoad != null) onLoad(this);
			scope.manager.itemEnd(url);
		};
		var onImageError = function(event:Dynamic):Void {
			removeEventListeners();
			if (onError != null) onError(event);
			scope.manager.itemError(url);
			scope.manager.itemEnd(url);
		};
		var removeEventListeners = function():Void {
			image.removeEventListener("load", onImageLoad, false);
			image.removeEventListener("error", onImageError, false);
		};
		image.addEventListener("load", onImageLoad, false);
		image.addEventListener("error", onImageError, false);
		if (url.substring(0, 5) != "data:") {
			if (this.crossOrigin != null) image.crossOrigin = this.crossOrigin;
		}
		this.manager.itemStart(url);
		image.src = url;
		return image;
	}

}

export class ImageLoader {
}