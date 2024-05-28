package three.loaders;

import three.loaders.Loader;
import three.loaders.Cache;

class HttpError extends Error {
    public var response:Dynamic;

    public function new(message:String, response:Dynamic) {
        super(message);
        this.response = response;
    }
}

class FileLoader extends Loader {
    private var loading:Map<String, Array<{onLoad:Dynamic->Void, onProgress:ProgressEvent->Void, onError:Error->Void}>>;
    private var mimeType:String;
    private var responseType:String;
    private var requestHeader:Map<String, String>;
    private var withCredentials:Bool;

    public function new(manager:Loader) {
        super(manager);
        loading = new Map<String, Array<{onLoad:Dynamic->Void, onProgress:ProgressEvent->Void, onError:Error->Void}>>();
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:ProgressEvent->Void, onError:Error->Void):Void {
        if (url == null) url = '';

        if (path != null) url = path + url;

        url = manager.resolveURL(url);

        var cached = Cache.get(url);

        if (cached != null) {
            manager.itemStart(url);
            haxe.Timer.delay(function() {
                if (onLoad != null) onLoad(cached);
                manager.itemEnd(url);
            }, 0);
            return cached;
        }

        if (loading.exists(url)) {
            loading.get(url).push({onLoad: onLoad, onProgress: onProgress, onError: onError});
            return;
        }

        loading.set(url, [{onLoad: onLoad, onProgress: onProgress, onError: onError}]);

        var req = new haxe.Http(url);
        req.headers = requestHeader;
        req.withCredentials = withCredentials;

        req.onProgress = function(event:ProgressEvent) {
            for (callback in loading.get(url)) {
                if (callback.onProgress != null) callback.onProgress(event);
            }
        };

        req.onError = function(error:Error) {
            for (callback in loading.get(url)) {
                if (callback.onError != null) callback.onError(error);
            }
        };

        req.onData = function(data:Dynamic) {
            Cache.add(url, data);
            for (callback in loading.get(url)) {
                if (callback.onLoad != null) callback.onLoad(data);
            }
            manager.itemEnd(url);
        };

        req.request();
    }

    public function setResponseType(value:String):FileLoader {
        responseType = value;
        return this;
    }

    public function setMimeType(value:String):FileLoader {
        mimeType = value;
        return this;
    }
}