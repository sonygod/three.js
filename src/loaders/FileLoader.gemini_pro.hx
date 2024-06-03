import Cache from "./Cache";
import Loader from "./Loader";

class HttpError extends Error {
	public response:Dynamic;

	public function new(message:String, response:Dynamic) {
		super(message);
		this.response = response;
	}
}

class FileLoader extends Loader {
	private static loading:Map<String, Array<Dynamic>> = new Map();

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
		if (url == null) url = "";
		if (this.path != null) url = this.path + url;
		url = this.manager.resolveURL(url);

		var cached = Cache.get(url);
		if (cached != null) {
			this.manager.itemStart(url);
			var _g = this;
			Timer.delay(function() {
				if (onLoad != null) onLoad(cached);
				_g.manager.itemEnd(url);
			}, 0);
			return cached;
		}

		if (FileLoader.loading.exists(url)) {
			FileLoader.loading.get(url).push({
				onLoad: onLoad,
				onProgress: onProgress,
				onError: onError
			});
			return;
		}

		FileLoader.loading.set(url, [{
			onLoad: onLoad,
			onProgress: onProgress,
			onError: onError
		}]);
		var req = new haxe.Http.Request(url);
		req.setHeader("credentials", this.withCredentials ? "include" : "same-origin");
		for (header in this.requestHeader) {
			req.setHeader(header, this.requestHeader[header]);
		}
		var mimeType = this.mimeType;
		var responseType = this.responseType;
		var _g1 = this;
		req.onData(function(data:haxe.io.Bytes) {
			var callbacks = FileLoader.loading.get(url);
			var total = 0;
			var lengthComputable = false;
			var loaded = 0;
			if (data.length == 0) {
				lengthComputable = true;
				total = 1;
				loaded = 1;
			} else {
				lengthComputable = true;
				total = data.length;
				loaded = data.length;
			}
			for (i in 0...callbacks.length) {
				var callback = callbacks[i];
				if (callback.onProgress != null) callback.onProgress({
					lengthComputable: lengthComputable,
					loaded: loaded,
					total: total
				});
			}
		});
		req.onError(function(err:Dynamic) {
			var callbacks = FileLoader.loading.get(url);
			if (callbacks == null) {
				_g1.manager.itemError(url);
				throw err;
			}
			FileLoader.loading.remove(url);
			for (i in 0...callbacks.length) {
				var callback = callbacks[i];
				if (callback.onError != null) callback.onError(err);
			}
			_g1.manager.itemError(url);
		});
		req.onComplete(function(response:Dynamic) {
			var callbacks = FileLoader.loading.get(url);
			if (callbacks == null) {
				_g1.manager.itemError(url);
				return;
			}
			FileLoader.loading.remove(url);
			for (i in 0...callbacks.length) {
				var callback = callbacks[i];
				if (callback.onLoad != null) {
					var _g2 = callback.onLoad;
					switch (responseType) {
						case "arraybuffer":
							_g2(response.response.buffer);
							break;
						case "blob":
							_g2(response.response);
							break;
						case "document":
							_g2(haxe.xml.Xml.parse(response.response));
							break;
						case "json":
							_g2(haxe.Json.parse(response.response));
							break;
						default:
							if (mimeType == null) {
								_g2(response.response);
							} else {
								var decoder = new haxe.io.BytesInput(response.response);
								_g2(decoder.toString());
							}
					}
				}
			}
			Cache.add(url, response.response);
			_g1.manager.itemEnd(url);
		});
		this.manager.itemStart(url);
		req.request();
	}

	public function setResponseType(value:String):FileLoader {
		this.responseType = value;
		return this;
	}

	public function setMimeType(value:String):FileLoader {
		this.mimeType = value;
		return this;
	}
}

export default FileLoader;