import js.html.Headers;
import js.html.Request;
import js.html.Response;
import js.html.ProgressEvent;
import js.html.ReadableStream;
import js.html.ReadableStreamController;
import js.html.RequestInit;

class HttpError extends Error {
    public var response:Response;

    public function new(message:String, response:Response) {
        super(message);
        this.response = response;
    }
}

class FileLoader extends Loader {
    private static var loading:Map<String, Array<{onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic}>> = new Map();

    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
        if (url == null) url = '';
        if (this.path != null) url = this.path + url;

        url = this.manager.resolveURL(url);

        var cached = Cache.get(url);
        if (cached != null) {
            this.manager.itemStart(url);
            haxe.Timer.delay(() -> {
                if (onLoad != null) onLoad(cached);
                this.manager.itemEnd(url);
            }, 0);
            return cached;
        }

        if (FileLoader.loading.exists(url)) {
            FileLoader.loading.get(url).push({onLoad: onLoad, onProgress: onProgress, onError: onError});
            return;
        }

        FileLoader.loading.set(url, [{onLoad: onLoad, onProgress: onProgress, onError: onError}]);

        var headers = new Headers();
        for (header in this.requestHeader) {
            headers.append(header.key, header.value);
        }
        
        var req = new Request(url, {
            headers: headers,
            credentials: this.withCredentials ? "include" : "same-origin"
        });

        var mimeType = this.mimeType;
        var responseType = this.responseType;

        js.Browser.fetch(req).then(response -> {
            if (response.status == 200 || response.status == 0) {
                if (response.status == 0) {
                    trace('THREE.FileLoader: HTTP Status 0 received.');
                }

                if (untyped __js__('typeof ReadableStream') == 'undefined' || response.body == null || response.body.getReader == null) {
                    return response;
                }

                var callbacks = FileLoader.loading.get(url);
                var reader = response.body.getReader();

                var contentLength = response.headers.get('X-File-Size') || response.headers.get('Content-Length');
                var total = contentLength != null ? Std.parseInt(contentLength) : 0;
                var lengthComputable = total != 0;
                var loaded = 0;

                var stream = new ReadableStream({
                    start: function(controller:ReadableStreamController) {
                        readData();
                        
                        function readData() {
                            reader.read().then(function(result) {
                                var done = result.done;
                                var value = result.value;
                                
                                if (done) {
                                    controller.close();
                                } else {
                                    loaded += value.byteLength;

                                    var event = new ProgressEvent('progress', {lengthComputable: lengthComputable, loaded: loaded, total: total});
                                    for (callback in callbacks) {
                                        if (callback.onProgress != null) callback.onProgress(event);
                                    }

                                    controller.enqueue(value);
                                    readData();
                                }
                            }).catch(function(e) {
                                controller.error(e);
                            });
                        }
                    }
                });

                return new Response(stream);
            } else {
                throw new HttpError('fetch for "' + response.url + '" responded with ' + response.status + ': ' + response.statusText, response);
            }
        }).then(response -> {
            switch (responseType) {
                case 'arraybuffer':
                    return response.arrayBuffer();
                case 'blob':
                    return response.blob();
                case 'document':
                    return response.text().then(text -> {
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
                        var label = exec != null && exec.matched(1) ? exec.matched(1).toLowerCase() : null;
                        var decoder = new js.html.TextDecoder(label);
                        return response.arrayBuffer().then(ab -> decoder.decode(ab));
                    }
            }
        }).then(data -> {
            Cache.add(url, data);

            var callbacks = FileLoader.loading.get(url);
            FileLoader.loading.remove(url);

            for (callback in callbacks) {
                if (callback.onLoad != null) callback.onLoad(data);
            }
        }).catch(err -> {
            var callbacks = FileLoader.loading.get(url);

            if (callbacks == null) {
                this.manager.itemError(url);
                throw err;
            }

            FileLoader.loading.remove(url);

            for (callback in callbacks) {
                if (callback.onError != null) callback.onError(err);
            }

            this.manager.itemError(url);
        }).finally(() -> {
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