package three.loaders;

import three.loaders.Cache;
import three.loaders.Loader;

class HttpError extends Error {
    public var response:Dynamic;

    public function new(message:String, response:Dynamic) {
        super(message);
        this.response = response;
    }
}

class FileLoader extends Loader {
    private var path:String;
    private var requestHeader:Dynamic;
    private var withCredentials:Bool;
    private var mimeType:String;
    private var responseType:String;

    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:ProgressEvent->Void, onError:Error->Void) {
        if (url == null) url = '';

        if (path != null) url = path + url;

        url = manager.resolveURL(url);

        var cached = Cache.get(url);

        if (cached != null) {
            manager.itemStart(url);

            haxe.Timer.delay(() -> {
                if (onLoad != null) onLoad(cached);
                manager.itemEnd(url);
            }, 0);

            return cached;
        }

        if (loading[url] != null) {
            loading[url].push({ onLoad: onLoad, onProgress: onProgress, onError: onError });
            return;
        }

        loading[url] = [];

        loading[url].push({ onLoad: onLoad, onProgress: onProgress, onError: onError });

        var req = new haxe.Http(url);
        req.headers = new haxe.HttpHeader();
        req.withCredentials = withCredentials;
        // An abort controller could be added within a future PR

        var mimeType = this.mimeType;
        var responseType = this.responseType;

        req.onData = function(data:String) {
            // ...
        };

        req.onError = function(error:Error) {
            // ...
        };

        req.onStatus = function(status:Int) {
            if (status == 200 || status == 0) {
                // ...
            } else {
                throw new HttpError('fetch for "${url}" responded with ${status}: ${req.statusText}', req);
            }
        };

        req.request();
    }

    public function setResponseType(value:String) {
        responseType = value;
        return this;
    }

    public function setMimeType(value:String) {
        mimeType = value;
        return this;
    }
}