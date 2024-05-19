import js.Browser.fetch;
import js.Browser.createImageBitmap;
import js.Browser.console;

class ImageBitmapLoader extends Loader {

	public function new(manager:Dynamic) {
		super(manager);
		this.isImageBitmapLoader = true;
		if (typeof createImageBitmap === 'undefined') {
			console.warn('THREE.ImageBitmapLoader: createImageBitmap() not supported.');
		}
		if (typeof fetch === 'undefined') {
			console.warn('THREE.ImageBitmapLoader: fetch() not supported.');
		}
		this.options = { premultiplyAlpha: 'none' };
	}

	public function setOptions(options:Dynamic):Dynamic {
		this.options = options;
		return this;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
		if (url === undefined) url = '';
		if (this.path !== undefined) url = this.path + url;
		url = this.manager.resolveURL(url);
		var scope = this;
		var cached = Cache.get(url);
		if (cached !== undefined) {
			scope.manager.itemStart(url);
			if (cached.then) {
				cached.then(function(imageBitmap) {
					if (onLoad) onLoad(imageBitmap);
					scope.manager.itemEnd(url);
				}).catch(function(e) {
					if (onError) onError(e);
				});
				return;
			}
			setTimeout(function() {
				if (onLoad) onLoad(cached);
				scope.manager.itemEnd(url);
			}, 0);
			return cached;
		}
		var fetchOptions = {};
		fetchOptions.credentials = (this.crossOrigin === 'anonymous') ? 'same-origin' : 'include';
		fetchOptions.headers = this.requestHeader;
		var promise = fetch(url, fetchOptions).then(function(res) {
			return res.blob();
		}).then(function(blob) {
			return createImageBitmap(blob, js.Lib.extend(scope.options, { colorSpaceConversion: 'none' }));
		}).then(function(imageBitmap) {
			Cache.add(url, imageBitmap);
			if (onLoad) onLoad(imageBitmap);
			scope.manager.itemEnd(url);
			return imageBitmap;
		}).catch(function(e) {
			if (onError) onError(e);
			Cache.remove(url);
			scope.manager.itemError(url);
			scope.manager.itemEnd(url);
		});
		Cache.add(url, promise);
		scope.manager.itemStart(url);
	}
}