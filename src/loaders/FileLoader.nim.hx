import Cache.Cache;
import Loader.Loader;

class HttpError extends Error {

	public var response:Dynamic;

	public function new(message:String, response:Dynamic) {
		super(message);
		this.response = response;
	}

}

class FileLoader extends Loader {

	public function new(manager:Dynamic) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {

		if (url == null) url = '';

		if (this.path != null) url = this.path + url;

		url = this.manager.resolveURL(url);

		var cached = Cache.get(url);

		if (cached != null) {

			this.manager.itemStart(url);

			js.Browser.window.setTimeout(() -> {

				if (onLoad != null) onLoad(cached);

				this.manager.itemEnd(url);

			}, 0);

			return cached;

		}

		// Check if request is duplicate

		if (loading[url] != null) {

			loading[url].push({

				onLoad: onLoad,
				onProgress: onProgress,
				onError: onError

			});

			return;

		}

		// Initialise array for duplicate requests
		loading[url] = [];

		loading[url].push({
			onLoad: onLoad,
			onProgress: onProgress,
			onError: onError,
		});

		// create request
		var req = new Request(url, {
			headers: new Headers(this.requestHeader),
			credentials: this.withCredentials ? 'include' : 'same-origin',
			// An abort controller could be added within a future PR
		});

		// record states ( avoid data race )
		var mimeType = this.mimeType;
		var responseType = this.responseType;

		// start the fetch
		fetch(req)
			.then(response -> {

				if (response.status == 200 || response.status == 0) {

					// Some browsers return HTTP Status 0 when using non-http protocol
					// e.g. 'file://' or 'data://'. Handle as success.

					if (response.status == 0) {

						js.Lib.console.warn('THREE.FileLoader: HTTP Status 0 received.');

					}

					// Workaround: Checking if response.body === undefined for Alipay browser #23548

					if (Type.typeof(ReadableStream) == 'undefined' || response.body == null || response.body.getReader == null) {

						return response;

					}

					var callbacks = loading[url];
					var reader = response.body.getReader();

					// Nginx needs X-File-Size check
					// https://serverfault.com/questions/482875/why-does-nginx-remove-content-length-header-for-chunked-content
					var contentLength = response.headers.get('X-File-Size') || response.headers.get('Content-Length');
					var total = contentLength != null ? Std.parseInt(contentLength) : 0;
					var lengthComputable = total != 0;
					var loaded = 0;

					// periodically read data into the new stream tracking while download progress
					var stream = new ReadableStream({
						start(controller) {

							readData();

							function readData() {

								reader.read().then(({ done, value }) -> {

									if (done) {

										controller.close();

									} else {

										loaded += value.byteLength;

										var event = new ProgressEvent('progress', { lengthComputable, loaded, total });
										for (i in 0...callbacks.length) {

											var callback = callbacks[i];
											if (callback.onProgress != null) callback.onProgress(event);

										}

										controller.enqueue(value);
										readData();

									}

								}, (e) -> {

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
			.then(response -> {

				switch (responseType) {

					case 'arraybuffer':

						return response.arrayBuffer();

					case 'blob':

						return response.blob();

					case 'document':

						return response.text()
							.then(text -> {

								var parser = new DOMParser();
								return parser.parseFromString(text, mimeType);

							});

					case 'json':

						return response.json();

					default:

						if (mimeType == null) {

							return response.text();

						} else {

							// sniff encoding
							var re = /charset="?([^;"\s]*)"?/i;
							var exec = re.exec(mimeType);
							var label = exec != null && exec[1] != null ? exec[1].toLowerCase() : null;
							var decoder = new TextDecoder(label);
							return response.arrayBuffer().then(ab -> decoder.decode(ab));

						}

				}

			})
			.then(data -> {

				// Add to cache only on HTTP success, so that we do not cache
				// error response bodies as proper responses to requests.
				Cache.add(url, data);

				var callbacks = loading[url];
				delete loading[url];

				for (i in 0...callbacks.length) {

					var callback = callbacks[i];
					if (callback.onLoad != null) callback.onLoad(data);

				}

			})
			.catch(err -> {

				// Abort errors and other errors are handled the same

				var callbacks = loading[url];

				if (callbacks == null) {

					// When onLoad was called and url was deleted in `loading`
					this.manager.itemError(url);
					throw err;

				}

				delete loading[url];

				for (i in 0...callbacks.length) {

					var callback = callbacks[i];
					if (callback.onError != null) callback.onError(err);

				}

				this.manager.itemError(url);

			})
			.finally(() -> {

				this.manager.itemEnd(url);

			});

		this.manager.itemStart(url);

	}

	public function setResponseType(value:String) {

		this.responseType = value;
		return this;

	}

	public function setMimeType(value:String) {

		this.mimeType = value;
		return this;

	}

}