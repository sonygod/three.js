import Cache.Cache;
import Loader.Loader;

class ImageBitmapLoader extends Loader {

	public var isImageBitmapLoader:Bool = true;
	public var options:Dynamic = { premultiplyAlpha: 'none' };

	public function new(manager:Dynamic) {
		super(manager);

		if (Std.is(Type.typeof(js.Browser.createImageBitmap), Void)) {
			trace.warn('THREE.ImageBitmapLoader: createImageBitmap() not supported.');
		}

		if (Std.is(Type.typeof(js.Browser.fetch), Void)) {
			trace.warn('THREE.ImageBitmapLoader: fetch() not supported.');
		}
	}

	public function setOptions(options:Dynamic):ImageBitmapLoader {
		this.options = options;
		return this;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
		if (url == null) url = '';

		if (this.path != null) url = this.path + url;

		url = this.manager.resolveURL(url);

		var cached = Cache.get(url);

		if (cached != null) {
			this.manager.itemStart(url);

			if (Std.is(cached, Promise)) {
				cached.then(function(imageBitmap) {
					if (onLoad != null) onLoad(imageBitmap);
					this.manager.itemEnd(url);
				}).catch(function(e) {
					if (onError != null) onError(e);
				});
				return;
			}

			js.Browser.window.setTimeout(function() {
				if (onLoad != null) onLoad(cached);
				this.manager.itemEnd(url);
			}, 0);

			return cached;
		}

		var fetchOptions = { };
		fetchOptions.credentials = (this.crossOrigin == 'anonymous') ? 'same-origin' : 'include';
		fetchOptions.headers = this.requestHeader;

		var promise = js.Browser.fetch(url, fetchOptions).then(function(res) {
			return res.blob();
		}).then(function(blob) {
			return js.Browser.createImageBitmap(blob, Reflect.field(this.options, 'premultiplyAlpha'), 'none');
		}).then(function(imageBitmap) {
			Cache.add(url, imageBitmap);
			if (onLoad != null) onLoad(imageBitmap);
			this.manager.itemEnd(url);
			return imageBitmap;
		}).catch(function(e) {
			if (onError != null) onError(e);
			Cache.remove(url);
			this.manager.itemError(url);
			this.manager.itemEnd(url);
		});

		Cache.add(url, promise);
		this.manager.itemStart(url);
	}

}

export class ImageBitmapLoader;