import haxe.Http;
import haxe.io.Bytes;

class HttpError extends Error {
	public response:Dynamic;

	public function new(message:String, response:Dynamic) {
		super(message);
		this.response = response;
	}
}

class FileLoader {
	private manager:Dynamic;
	private path:String;
	private requestHeader:Dynamic;
	private withCredentials:Bool;
	private mimeType:String;
	private responseType:String;

	public function new(manager:Dynamic) {
		this.manager = manager;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
		if (url == null) {
			url = '';
		}

		if (this.path != null) {
			url = this.path + url;
		}

		url = this.manager.resolveURL(url);

		var cached = Cache.get(url);
		if (cached != null) {
			this.manager.itemStart(url);

			haxe.Timer.delay(function() {
				if (onLoad != null) {
					onLoad(cached);
				}

				this.manager.itemEnd(url);
			}, 0);

			return cached;
		}

		// Check if request is duplicate
		if (loading.exists(url)) {
			loading.get(url).push({
				onLoad: onLoad,
				onProgress: onProgress,
				onError: onError
			});
			return;
		}

		// Initialise array for duplicate requests
		loading.set(url, []);

		loading.get(url).push({
			onLoad: onLoad,
			onProgress: onProgress,
			onError: onError
		});

		// Create request
		var http:Http = new Http(url);
		http.setHeader(this.requestHeader);
		http.withCredentials = this.withCredentials;

		// Record states (avoid data race)
		var mimeType = this.mimeType;
		var responseType = this.responseType;

		// Start the request
		http.send(function(status:Int) {
			if (status == Http.Status.SUCCESS || status == Http.Status.CONNECT_ERROR) {
				var callbacks = loading.get(url);
				var data:Dynamic;

				switch (responseType) {
					case 'arraybuffer':
						data = http.responseBytes.toArrayBuffer();
						break;
					case 'blob':
						data = http.responseBytes;
						break;
					case 'document':
						data = new DOMParser().parseFromString(http.response, mimeType);
						break;
					case 'json':
						data = Json.parse(http.response);
						break;
					default:
						if (mimeType == null) {
							data = http.response;
						} else {
							// Sniff encoding
							var re = ~/charset="?([^;"\s]*)"?/i;
							var label = re.exec(mimeType)[1].toLowerCase();
							var decoder = new TextDecoder(label);
							data = decoder.decode(http.responseBytes.toArrayBuffer());
						}
				}

				// Add to cache only on HTTP success, so that we do not cache
				// error response bodies as proper responses to requests.
				Cache.add(url, data);

				for (callback in callbacks) {
					if (callback.onLoad != null) {
						callback.onLoad(data);
					}
				}

				loading.remove(url);
				this.manager.itemEnd(url);
			} else {
				var callbacks = loading.get(url);
				loading.remove(url);

				for (callback in callbacks) {
					if (callback.onError != null) {
						callback.onError(new HttpError('Failed to load ' + url, {status: status}));
					}
				}

				this.manager.itemError(url);
			}
		});

		this.manager.itemStart(url);
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

class Cache {
	private static cache:Map<String, Dynamic> = new Map();

	public static function get(url:String):Dynamic {
		return cache.get(url);
	}

	public static function add(url:String, data:Dynamic):Void {
		cache.set(url, data);
	}
}

var loading:Map<String, Array<{onLoad: Dynamic, onProgress: Dynamic, onError: Dynamic}>> = new Map();