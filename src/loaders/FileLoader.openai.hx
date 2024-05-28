package three.loaders;

import haxe.Http;
import js.html.XMLHttpRequest;
import js.html.ProgressEvent;
import js.Error;

class HttpError extends Error {
    public var response:Dynamic;

    public function new(message:String, response:Dynamic) {
        super(message);
        this.response = response;
    }
}

class FileLoader extends Loader {
    private var path:String;
    private var manager:Loader;
    private var mimeType:String;
    private var responseType:String;
    private var withCredentials:Bool;
    private var requestHeader:HttpHeader;

    public function new(manager:Loader) {
        super(manager);
        this.manager = manager;
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:ProgressEvent->Void, onError:Error->Void):Void {
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

        var req = new XMLHttpRequest();
        req.open("GET", url, true);
        req.responseType = responseType;
        req.setRequestHeader("Content-Type", mimeType);
        if (withCredentials) req.withCredentials = true;

        req.onload = function(_:Dynamic) {
            if (req.status == 200 || req.status == 0) {
                if (req.status == 0) {
                    trace("THREE.FileLoader: HTTP Status 0 received.");
                }

                var callbacks = loading[url];
                delete loading[url];

                for (i in 0...callbacks.length) {
                    var callback = callbacks[i];
                    if (callback.onLoad != null) callback.onLoad(req.response);
                }
            } else {
                throw new HttpError("fetch for \"$url\" responded with ${req.status}: ${req.statusText}", req);
            }
        };

        req.onprogress = function(e:ProgressEvent) {
            var callbacks = loading[url];
            for (i in 0...callbacks.length) {
                var callback = callbacks[i];
                if (callback.onProgress != null) callback.onProgress(e);
            }
        };

        req.onerror = function(e:Error) {
            var callbacks = loading[url];
            delete loading[url];
            for (i in 0...callbacks.length) {
                var callback = callbacks[i];
                if (callback.onError != null) callback.onError(e);
            }
            manager.itemError(url);
        };

        req.send();
        manager.itemStart(url);
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