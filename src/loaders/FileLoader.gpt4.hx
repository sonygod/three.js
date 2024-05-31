import three.loaders.Cache;
import three.loaders.Loader;

typedef Callback = {
    var onLoad: Dynamic->Void,
    var onProgress: Dynamic->Void,
    var onError: Dynamic->Void
};

var loading:Map<String, Array<Callback>> = new Map();

class HttpError extends haxe.Exception {
    public var response:Dynamic;

    public function new(message:String, response:Dynamic) {
        super(message);
        this.response = response;
    }
}

class FileLoader extends Loader {
    public var responseType:String;
    public var mimeType:String;

    public function new(manager:Dynamic) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Dynamic {
        if (url == null) url = '';
        if (this.path != null) url = this.path + url;

        url = this.manager.resolveURL(url);

        var cached = Cache.get(url);
        if (cached != null) {
            this.manager.itemStart(url);

            haxe.Timer.delay(function() {
                if (onLoad != null) onLoad(cached);
                this.manager.itemEnd(url);
            }, 0);

            return cached;
        }

        if (loading.exists(url)) {
            loading.get(url).push({onLoad: onLoad, onProgress: onProgress, onError: onError});
            return null;
        }

        loading.set(url, [{onLoad: onLoad, onProgress: onProgress, onError: onError}]);

        var req = new js.html.Request(url, {
            headers: new js.html.Headers(this.requestHeader),
            credentials: this.withCredentials ? 'include' : 'same-origin'
        });

        var mimeType = this.mimeType;
        var responseType = this.responseType;

        js.Browser.window.fetch(req).then(function(response) {
            if (response.status == 200 || response.status == 0) {
                if (response.status == 0) {
                    js.Browser.console.warn('THREE.FileLoader: HTTP Status 0 received.');
                }

                if (js.html.ReadableStream == null || response.body == null || response.body.getReader == null) {
                    return response;
                }

                var callbacks = loading.get(url);
                var reader = response.body.getReader();
                var contentLength = response.headers.get('X-File-Size') ?? response.headers.get('Content-Length');
                var total = contentLength != null ? Std.parseInt(contentLength) : 0;
                var lengthComputable = total != 0;
                var loaded = 0;

                var stream = new js.html.ReadableStream({
                    start: function(controller) {
                        function readData() {
                            reader.read().then(function(result) {
                                if (result.done) {
                                    controller.close();
                                } else {
                                    loaded += result.value.byteLength;

                                    var event = new js.html.ProgressEvent('progress', {
                                        lengthComputable: lengthComputable,
                                        loaded: loaded,
                                        total: total
                                    });

                                    for (callback in callbacks) {
                                        if (callback.onProgress != null) callback.onProgress(event);
                                    }

                                    controller.enqueue(result.value);
                                    readData();
                                }
                            }).catch(function(e) {
                                controller.error(e);
                            });
                        }

                        readData();
                    }
                });

                return new js.html.Response(stream);
            } else {
                throw new HttpError('fetch for "${response.url}" responded with ${response.status}: ${response.statusText}', response);
            }
        }).then(function(response) {
            switch (responseType) {
                case 'arraybuffer':
                    return response.arrayBuffer();
                case 'blob':
                    return response.blob();
                case 'document':
                    return response.text().then(function(text) {
                        var parser = new js.html.DOMParser();
                        return parser.parseFromString(text, mimeType);
                    });
                case 'json':
                    return response.json();
                default:
                    if (mimeType == null) {
                        return response.text();
                    } else {
                        var re = ~/charset="?([^;"\s]*)"?/i;
                        var exec = re.match(mimeType);
                        var label = exec != null && exec.matched(1) != null ? exec.matched(1).toLowerCase() : null;
                        var decoder = new js.html.TextDecoder(label);
                        return response.arrayBuffer().then(function(ab) {
                            return decoder.decode(ab);
                        });
                    }
            }
        }).then(function(data) {
            Cache.add(url, data);
            var callbacks = loading.get(url);
            loading.remove(url);

            for (callback in callbacks) {
                if (callback.onLoad != null) callback.onLoad(data);
            }
        }).catch(function(err) {
            var callbacks = loading.get(url);
            if (callbacks == null) {
                this.manager.itemError(url);
                throw err;
            }

            loading.remove(url);

            for (callback in callbacks) {
                if (callback.onError != null) callback.onError(err);
            }

            this.manager.itemError(url);
        }).finally(function() {
            this.manager.itemEnd(url);
        });

        this.manager.itemStart(url);
        return null;
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