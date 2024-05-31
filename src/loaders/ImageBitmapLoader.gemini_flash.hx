import three.loaders.Loader;
import three.loaders.Cache;

class ImageBitmapLoader extends Loader {

	public var isImageBitmapLoader:Bool = true;

	public var options:Dynamic;

	public function new(manager:Loader) {
		super(manager);
		if (js.Lib.isUndefined(js.Browser.createImageBitmap)) {
			Sys.warning("THREE.ImageBitmapLoader: createImageBitmap() not supported.");
		}
		if (js.Lib.isUndefined(js.Browser.fetch)) {
			Sys.warning("THREE.ImageBitmapLoader: fetch() not supported.");
		}
		this.options = {premultiplyAlpha: "none"};
	}

	public function setOptions(options:Dynamic):ImageBitmapLoader {
		this.options = options;
		return this;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
		if (url == null) url = "";
		if (this.path != null) url = this.path + url;
		url = this.manager.resolveURL(url);
		var scope = this;
		var cached = Cache.get(url);
		if (cached != null) {
			this.manager.itemStart(url);
			if (js.Lib.is(cached, js.lib.Promise)) {
				cached.then(function(imageBitmap:Dynamic) {
					if (onLoad != null) onLoad(imageBitmap);
					scope.manager.itemEnd(url);
				}).catch(function(e:Dynamic) {
					if (onError != null) onError(e);
				});
				return cached;
			}
			js.Lib.setTimeout(function() {
				if (onLoad != null) onLoad(cached);
				scope.manager.itemEnd(url);
			}, 0);
			return cached;
		}
		var fetchOptions = {};
		fetchOptions.credentials = (this.crossOrigin == "anonymous") ? "same-origin" : "include";
		fetchOptions.headers = this.requestHeader;
		var promise = js.Browser.fetch(url, fetchOptions).then(function(res:Dynamic) {
			return res.blob();
		}).then(function(blob:Dynamic) {
			return js.Browser.createImageBitmap(blob, js.Boot.cast(js.Lib.assign({colorSpaceConversion: "none"}, scope.options)));
		}).then(function(imageBitmap:Dynamic) {
			Cache.add(url, imageBitmap);
			if (onLoad != null) onLoad(imageBitmap);
			scope.manager.itemEnd(url);
			return imageBitmap;
		}).catch(function(e:Dynamic) {
			if (onError != null) onError(e);
			Cache.remove(url);
			scope.manager.itemError(url);
			scope.manager.itemEnd(url);
		});
		Cache.add(url, promise);
		this.manager.itemStart(url);
		return promise;
	}
}