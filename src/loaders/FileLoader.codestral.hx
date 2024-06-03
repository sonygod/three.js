import js.Browser.fetch;
import js.html.DOMParser;
import js.html.TextDecoder;
import js.html.ProgressEvent;
import js.html.Response;
import js.html.Headers;
import js.html.Request;
import threejs.loaders.Cache;
import threejs.loaders.Loader;

class HttpError extends Error {
    public var response: Response;
    public function new(message: String, response: Response) {
        super(message);
        this.response = response;
    }
}

class FileLoader extends Loader {
    private var loading: haxe.ds.StringMap<Array<Dynamic>> = new haxe.ds.StringMap<Array<Dynamic>>();

    public function new(manager: Dynamic) {
        super(manager);
    }

    public function load(url: String, onLoad: Null<Function>, onProgress: Null<Function>, onError: Null<Function>) {
        if (url == null) url = "";
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

        if (loading.exists(url)) {
            loading.get(url).push({
                onLoad: onLoad,
                onProgress: onProgress,
                onError: onError
            });
            return;
        }

        loading.set(url, [{
            onLoad: onLoad,
            onProgress: onProgress,
            onError: onError,
        }]);

        var req = new Request(url, {
            headers: new Headers(this.requestHeader),
            credentials: this.withCredentials ? 'include' : 'same-origin',
        });

        var mimeType = this.mimeType;
        var responseType = this.responseType;

        fetch(req)
            .then((response: Response) => {
                if (response.status === 200 || response.status === 0) {
                    if (response.status === 0) {
                        js.Browser.console.warn("THREE.FileLoader: HTTP Status 0 received.");
                    }

                    if (js.html.window.ReadableStream == null || response.body == null || response.body.getReader == null) {
                        return response;
                    }

                    var callbacks = loading.get(url);
                    var reader = response.body.getReader();
                    var contentLength = response.headers.get('X-File-Size') || response.headers.get('Content-Length');
                    var total = contentLength != null ? Std.parseInt(contentLength) : 0;
                    var lengthComputable = total !== 0;
                    var loaded = 0;

                    var stream = new js.html.ReadableStream({
                        start: (controller: js.html.ReadableStreamDefaultController) => {
                            readData();

                            function readData() {
                                reader.read().then(({done, value}: {done: Bool, value: js.html.ArrayBuffer}) => {
                                    if (done) {
                                        controller.close();
                                    } else {
                                        loaded += value.byteLength;
                                        var event = new ProgressEvent('progress', {lengthComputable: lengthComputable, loaded: loaded, total: total});
                                        for (i in 0...callbacks.length) {
                                            var callback = callbacks[i];
                                            if (callback.onProgress != null) callback.onProgress(event);
                                        }
                                        controller.enqueue(value);
                                        readData();
                                    }
                                }, (e: Dynamic) => {
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
            .then((response: Response) => {
                switch (responseType) {
                    case 'arraybuffer':
                        return response.arrayBuffer();
                    case 'blob':
                        return response.blob();
                    case 'document':
                        return response.text()
                            .then((text: String) => {
                                var parser = new DOMParser();
                                return parser.parseFromString(text, mimeType);
                            });
                    case 'json':
                        return response.json();
                    default:
                        if (mimeType == null) {
                            return response.text();
                        } else {
                            var re = new EReg("charset=\"?([^\";]*)\"?", "i");
                            var exec = re.match(mimeType);
                            var label = exec != null && exec[1] != null ? exec[1].toLowerCase() : null;
                            var decoder = new TextDecoder(label);
                            return response.arrayBuffer().then((ab: js.html.ArrayBuffer) => decoder.decode(ab));
                        }
                }
            })
            .then((data: Dynamic) => {
                Cache.add(url, data);
                var callbacks = loading.get(url);
                loading.remove(url);
                for (i in 0...callbacks.length) {
                    var callback = callbacks[i];
                    if (callback.onLoad != null) callback.onLoad(data);
                }
            })
            .catch((err: Dynamic) => {
                var callbacks = loading.get(url);
                if (callbacks == null) {
                    this.manager.itemError(url);
                    throw err;
                }
                loading.remove(url);
                for (i in 0...callbacks.length) {
                    var callback = callbacks[i];
                    if (callback.onError != null) callback.onError(err);
                }
                this.manager.itemError(url);
            })
            .finally(() => {
                this.manager.itemEnd(url);
            });

        this.manager.itemStart(url);
    }

    public function setResponseType(value: String): FileLoader {
        this.responseType = value;
        return this;
    }

    public function setMimeType(value: String): FileLoader {
        this.mimeType = value;
        return this;
    }
}