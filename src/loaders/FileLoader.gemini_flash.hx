import haxe.io.Bytes;
import haxe.io.Eof;
import haxe.io.Output;
import haxe.io.StringTools;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.FileReader;
import haxe.io.Path;
import haxe.io.Encoding;
import haxe.io.File;
import haxe.io.FileInput;

import js.html.DomParser;
import js.html.Window;
import js.html.Request;
import js.html.Response;
import js.html.Headers;
import js.html.URL;
import js.html.ProgressEvent;

import three.loaders.Cache;
import three.loaders.Loader;

class HttpError extends Error {

	public var response:Response;

	public function new(message:String, response:Response) {
		super(message);
		this.response = response;
	}
}

class FileLoader extends Loader {

	public var responseType:String = "arraybuffer";
	public var mimeType:String;

	public function new(manager:Loader = null) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:ProgressEvent->Void, onError:Dynamic->Void):Dynamic {
		if (url == null) url = "";
		if (this.path != null) url = this.path + url;
		url = this.manager.resolveURL(url);

		var cached = Cache.get(url);
		if (cached != null) {
			this.manager.itemStart(url);
			// setTimeout(() => {
			// 	if (onLoad != null) onLoad(cached);
			// 	this.manager.itemEnd(url);
			// }, 0);
			Window.setTimeout(() => {
				if (onLoad != null) onLoad(cached);
				this.manager.itemEnd(url);
			}, 0);
			return cached;
		}

		// Check if request is duplicate
		// if (loading[url] != null) {
		// 	loading[url].push({
		// 		onLoad: onLoad,
		// 		onProgress: onProgress,
		// 		onError: onError
		// 	});
		// 	return;
		// }

		// Initialise array for duplicate requests
		// loading[url] = [];
		// loading[url].push({
		// 	onLoad: onLoad,
		// 	onProgress: onProgress,
		// 	onError: onError
		// });

		// create request
		var req = new Request(url, {
			headers: new Headers(this.requestHeader),
			credentials: this.withCredentials ? 'include' : 'same-origin'
			// An abort controller could be added within a future PR
		});

		// record states ( avoid data race )
		var mimeType = this.mimeType;
		var responseType = this.responseType;

		// start the fetch
		Window.fetch(req)
			.then(response => {
				if (response.status == 200 || response.status == 0) {
					// Some browsers return HTTP Status 0 when using non-http protocol
					// e.g. 'file://' or 'data://'. Handle as success.
					if (response.status == 0) {
						console.warn("THREE.FileLoader: HTTP Status 0 received.");
					}

					// Workaround: Checking if response.body === undefined for Alipay browser #23548
					if (typeof(ReadableStream) == 'undefined' || response.body == null || response.body.getReader == null) {
						return response;
					}

					// var callbacks = loading[url];
					var reader = response.body.getReader();
					// Nginx needs X-File-Size check
					// https://serverfault.com/questions/482875/why-does-nginx-remove-content-length-header-for-chunked-content
					var contentLength = response.headers.get('X-File-Size') || response.headers.get('Content-Length');
					var total = contentLength != null ? Std.parseInt(contentLength) : 0;
					var lengthComputable = total != 0;
					var loaded = 0;
					// periodically read data into the new stream tracking while download progress
					var stream = new ReadableStream({
						start: function(controller) {
							readData();
							function readData() {
								reader.read().then(function({done, value}) {
									if (done) {
										controller.close();
									} else {
										loaded += value.byteLength;
										var event = new ProgressEvent('progress', {
											lengthComputable: lengthComputable,
											loaded: loaded,
											total: total
										});
										// for (let i = 0, il = callbacks.length; i < il; i++) {
										// 	var callback = callbacks[i];
										// 	if (callback.onProgress != null) callback.onProgress(event);
										// }
										if (onProgress != null) onProgress(event);
										controller.enqueue(value);
										readData();
									}
								}, function(e) {
									controller.error(e);
								});
							}
						}
					});

					return new Response(stream);
				} else {
					throw new HttpError("fetch for \"" + response.url + "\" responded with " + response.status + ": " + response.statusText, response);
				}
			})
			.then(response => {
				switch (responseType) {
					case "arraybuffer":
						return response.arrayBuffer();
					case "blob":
						return response.blob();
					case "document":
						return response.text()
							.then(text => {
								var parser = new DomParser();
								return parser.parseFromString(text, mimeType);
							});
					case "json":
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
							return response.arrayBuffer().then(ab => decoder.decode(ab));
						}
				}
			})
			.then(data => {
				// Add to cache only on HTTP success, so that we do not cache
				// error response bodies as proper responses to requests.
				Cache.add(url, data);
				// var callbacks = loading[url];
				// delete loading[url];
				// for (let i = 0, il = callbacks.length; i < il; i++) {
				// 	var callback = callbacks[i];
				// 	if (callback.onLoad != null) callback.onLoad(data);
				// }
				if (onLoad != null) onLoad(data);
			})
			.catch(err => {
				// Abort errors and other errors are handled the same
				// var callbacks = loading[url];
				// if (callbacks == null) {
				// 	// When onLoad was called and url was deleted in `loading`
				// 	this.manager.itemError(url);
				// 	throw err;
				// }
				// delete loading[url];
				// for (let i = 0, il = callbacks.length; i < il; i++) {
				// 	var callback = callbacks[i];
				// 	if (callback.onError != null) callback.onError(err);
				// }
				if (onError != null) onError(err);
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

class ReadableStream extends js.html.ReadableStream {
	public function new(options:js.html.ReadableStreamOptions) {
		this = js.html.ReadableStream.create(options);
	}
}

class TextDecoder extends js.html.TextDecoder {
	public function new(encoding:String) {
		this = js.html.TextDecoder.create(encoding);
	}
}

class TextEncoder extends js.html.TextEncoder {
	public function new() {
		this = js.html.TextEncoder.create();
	}
}

class Response extends js.html.Response {
	public function new(body:js.html.BodyInit, init:js.html.ResponseInit) {
		this = js.html.Response.create(body, init);
	}

	public function arrayBuffer():Dynamic {
		return js.html.Response.prototype.arrayBuffer.call(this);
	}

	public function blob():Dynamic {
		return js.html.Response.prototype.blob.call(this);
	}

	public function json():Dynamic {
		return js.html.Response.prototype.json.call(this);
	}

	public function text():Dynamic {
		return js.html.Response.prototype.text.call(this);
	}
}

class Request extends js.html.Request {
	public function new(input:String, init:js.html.RequestInit) {
		this = js.html.Request.create(input, init);
	}
}

class Headers extends js.html.Headers {
	public function new(init:Dynamic) {
		this = js.html.Headers.create(init);
	}

	public function get(name:String):String {
		return js.html.Headers.prototype.get.call(this, name);
	}
}

class ProgressEvent extends js.html.ProgressEvent {
	public function new(type:String, init:js.html.ProgressEventInit) {
		this = js.html.ProgressEvent.create(type, init);
	}
}

class URL extends js.html.URL {
	public function new(url:String) {
		this = js.html.URL.create(url);
	}
}

class Window extends js.html.Window {
	static public function fetch(req:Request):Dynamic {
		return js.html.Window.prototype.fetch.call(this, req);
	}

	static public function setTimeout(callback:Dynamic->Void, time:Int):Int {
		return js.html.Window.prototype.setTimeout.call(this, callback, time);
	}
}

class Cache {

	static public var cache:Map<String,Dynamic> = new Map();

	static public function get(url:String):Dynamic {
		return cache.get(url);
	}

	static public function add(url:String, data:Dynamic):Void {
		cache.set(url, data);
	}
}