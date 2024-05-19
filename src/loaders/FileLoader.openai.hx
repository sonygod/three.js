import three.Cache;
import three.Loader;

class HttpError extends Error {
    public var response:Dynamic;

    public function new(message:String, response:Dynamic) {
        super(message);
        this.response = response;
    }
}

class FileLoader extends Loader {
    public function new(manager) {
        super(manager);
    }

    public override function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        if (url == null) url = '';

        if (this.path != null) url = this.path + url;

        url = this.manager.resolveURL(url);

        var cached = Cache.get(url);

        if (cached != null) {
            this.manager.itemStart(url);

            haxe.Timer.delay(function () {
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
            onError: onError
        }]);

        var req:Request = new Request(url, {
            headers: new Headers(this.requestHeader),
            credentials: this.withCredentials ? 'include' : 'same-origin'
        });

        var mimeType:Null<String> = this.mimeType;
        var responseType:Null<String> = this.responseType;

        fetch(req)
            .then(function (response:Response) {
                if (response.status == 200 || response.status == 0) {
                    if (response.status == 0) {
                        console.warn('THREE.FileLoader: HTTP Status 0 received.');
                    }

                    if (js.Browser.window.ReadableStream == null || response.body == null || response.body.getReader == null) {
                        return response;
                    }

                    var callbacks:Array<Dynamic> = loading.get(url);
                    var reader = response.body.getReader();

                    var contentLength = response.headers.get('X-File-Size') || response.headers.get('Content-Length');
                    var total:Int = contentLength != null ? Std.parseInt(contentLength) : 0;
                    var lengthComputable:Bool = total != 0;
                    var loaded:Int = 0;

                    var stream = new js.Browser.window.ReadableStream({
                        start: function (controller) {
                            readData();

                            function readData() {
                                reader.read().then(function ({ done, value }) {
                                    if (done) {
                                        controller.close();
                                    } else {
                                        loaded += value.byteLength;

                                        var event = new js.Browser.window.ProgressEvent('progress', {
                                            lengthComputable: lengthComputable,
                                            loaded: loaded,
                                            total: total
                                        });

                                        for (i in 0...callbacks.length) {
                                            var callback = callbacks[i];
                                            if (callback.onProgress != null) callback.onProgress(event);
                                        }

                                        controller.enqueue(value);
                                        readData();
                                    }
                                }, function (e) {
                                    controller.error(e);
                                });
                            }
                        }
                    });

                    return new Response(stream);
                } else {
                    throw new HttpError('fetch for "' + response.url + '" responded with ' + response.status + ': ' + response.statusText, response);
                }
            })
            .then(function (response:Response) {
                switch (responseType) {
                    case 'arraybuffer':
                        return response.arrayBuffer();

                    case 'blob':
                        return response.blob();

                    case 'document':
                        return response.text()
                            .then(function (text:String) {
                                var parser = new DOMParser();
                                return parser.parseFromString(text, mimeType);
                            });

                    case 'json':
                        return response.json();

                    default:
                        if (mimeType == null) {
                            return response.text();
                        } else {
                            var re = /charset="?([^;"\s]*)"?/i;
                            var exec = re.exec(mimeType);
                            var label = exec != null && exec[1] != null ? exec[1].toLowerCase() : null;
                            var decoder = new TextDecoder(label);
                            return response.arrayBuffer().then(function (ab:js.typedarray.ArrayBuffer) {
                                return decoder.decode(ab);
                            });
                        }
                }
            })
            .then(function (data:Dynamic) {
                Cache.add(url, data);

                var callbacks:Array<Dynamic> = loading.get(url);
                loading.remove(url);

                for (i in 0...callbacks.length) {
                    var callback = callbacks[i];
                    if (callback.onLoad != null) callback.onLoad(data);
                }
            })
            .catch(function (err:Dynamic) {
                var callbacks:Array<Dynamic> = loading.get(url);

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
            .finally(function () {
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

class Request {
    public var url:String;
    public var init:Dynamic;

    public function new(url:String, init:Dynamic) {
        this.url = url;
        this.init = init;
    }
}

class Headers {
    public function new(init:Dynamic) {}

    public function get(name:String):Null<String> {
        return null;
    }
}

class ProgressEvent {
    public var lengthComputable:Bool;
    public var loaded:Int;
    public var total:Int;

    public function new(type:String, eventInitDict:Dynamic) {
        this.lengthComputable = eventInitDict.lengthComputable;
        this.loaded = eventInitDict.loaded;
        this.total = eventInitDict.total;
    }
}

class Response {
    public var url:String;
    public var headers:Headers;
    public var body:Dynamic;
    private var _status:Int;
    private var _statusText:String;

    public function new(url:String, options:Dynamic) {
        this.url = url;
        this.headers = null;
        this.body = null;
        this._status = 0;
        this._statusText = '';
    }

    public var status(get, null):Int;
    public var statusText(get, null):String;

    @:noCompletion
    public function arrayBuffer():Dynamic {}

    @:noCompletion
    public function blob():Dynamic {}

    @:noCompletion
    public function text():Dynamic {}

    @:noCompletion
    public function json():Dynamic {}
}