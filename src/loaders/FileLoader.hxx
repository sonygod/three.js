import js.Browser.fetch;
import js.Browser.Request;
import js.Browser.Headers;
import js.Browser.Response;
import js.Browser.ProgressEvent;
import js.Browser.ReadableStream;
import js.Browser.TextDecoder;
import js.Browser.DOMParser;

class HttpError extends Error {

	public var response:Response;

	public function new(message:String, response:Response) {
		super(message);
		this.response = response;
	}
}

class FileLoader extends Loader {

	public function new(manager:Manager) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Dynamic {
		if (url === undefined) url = '';
		if (this.path !== undefined) url = this.path + url;
		url = this.manager.resolveURL(url);
		var cached = Cache.get(url);
		if (cached !== undefined) {
			this.manager.itemStart(url);
			setTimeout(function() {
				if (onLoad) onLoad(cached);
				this.manager.itemEnd(url);
			}, 0);
			return cached;
		}
		if (loading[url] !== undefined) {
			loading[url].push({
				onLoad: onLoad,
				onProgress: onProgress,
				onError: onError
			});
			return;
		}
		loading[url] = [];
		loading[url].push({
			onLoad: onLoad,
			onProgress: onProgress,
			onError: onError
		});
		var req = new Request(url, {
			headers: new Headers(this.requestHeader),
			credentials: this.withCredentials ? 'include' : 'same-origin'
		});
		fetch(req)
			.then(response => {
				if (response.status === 200 || response.status === 0) {
					if (response.status === 0) {
						trace('THREE.FileLoader: HTTP Status 0 received.');
					}
					if (typeof ReadableStream === 'undefined' || response.body === undefined || response.body.getReader === undefined) {
						return response;
					}
					var callbacks = loading[url];
					var reader = response.body.getReader();
					var contentLength = response.headers.get('X-File-Size') || response.headers.get('Content-Length');
					var total = contentLength ? Std.parseInt(contentLength) : 0;
					var lengthComputable = total !== 0;
					var loaded = 0;
					var stream = new ReadableStream({
						start(controller) {
							readData();
							function readData() {
								reader.read().then(({done, value}) => {
									if (done) {
										controller.close();
									} else {
										loaded += value.byteLength;
										var event = new ProgressEvent('progress', {lengthComputable: lengthComputable, loaded: loaded, total: total});
										for (i in callbacks) {
											var callback = callbacks[i];
											if (callback.onProgress) callback.onProgress(event);
										}
										controller.enqueue(value);
										readData();
									}
								}, (e) => {
									controller.error(e);
								});
							}
						}
					});
					return new Response(stream);
				} else {
					throw new HttpError(`fetch for "${response.url}" responded with ${response.status}: ${response.statusText}`, response);
				}
			})
			.then(response => {
				switch (this.responseType) {
					case 'arraybuffer':
						return response.arrayBuffer();
					case 'blob':
						return response.blob();
					case 'document':
						return response.text().then(text => {
							var parser = new DOMParser();
							return parser.parseFromString(text, this.mimeType);
						});
					case 'json':
						return response.json();
					default:
						if (this.mimeType === undefined) {
							return response.text();
						} else {
							var re = /charset="?([^;"\s]*)"?/i;
							var exec = re.exec(this.mimeType);
							var label = exec && exec[1] ? exec[1].toLowerCase() : undefined;
							var decoder = new TextDecoder(label);
							return response.arrayBuffer().then(ab => decoder.decode(ab));
						}
				}
			})
			.then(data => {
				Cache.add(url, data);
				var callbacks = loading[url];
				delete loading[url];
				for (i in callbacks) {
					var callback = callbacks[i];
					if (callback.onLoad) callback.onLoad(data);
				}
			})
			.catch(err => {
				var callbacks = loading[url];
				if (callbacks === undefined) {
					this.manager.itemError(url);
					throw err;
				}
				delete loading[url];
				for (i in callbacks) {
					var callback = callbacks[i];
					if (callback.onError) callback.onError(err);
				}
				this.manager.itemError(url);
			})
			.finally(() => {
				this.manager.itemEnd(url);
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