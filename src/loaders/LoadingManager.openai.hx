package three.loaders;

import haxe.ds.Vector;

class LoadingManager {
    public var onStart:Void->Void;
    public var onLoad:Void->Void;
    public var onProgress:String->Int->Int->Void;
    public var onError:String->Void;

    private var isLoading:Bool = false;
    private var itemsLoaded:Int = 0;
    private var itemsTotal:Int = 0;
    private var urlModifier:String->String;
    private var handlers:Vector<String> = new Vector<String>();

    public function new(onLoad:Void->Void, onProgress:String->Int->Int->Void, onError:String->Void) {
        this.onLoad = onLoad;
        this.onProgress = onProgress;
        this.onError = onError;
    }

    public function itemStart(url:String) {
        itemsTotal++;
        if (!isLoading) {
            if (onStart != null) {
                onStart(url, itemsLoaded, itemsTotal);
            }
        }
        isLoading = true;
    }

    public function itemEnd(url:String) {
        itemsLoaded++;
        if (onProgress != null) {
            onProgress(url, itemsLoaded, itemsTotal);
        }
        if (itemsLoaded == itemsTotal) {
            isLoading = false;
            if (onLoad != null) {
                onLoad();
            }
        }
    }

    public function itemError(url:String) {
        if (onError != null) {
            onError(url);
        }
    }

    public function resolveURL(url:String):String {
        if (urlModifier != null) {
            return urlModifier(url);
        }
        return url;
    }

    public function setURLModifier(transform:String->String):LoadingManager {
        urlModifier = transform;
        return this;
    }

    public function addHandler(regex:String, loader:Dynamic) {
        handlers.push(regex);
        handlers.push(loader);
        return this;
    }

    public function removeHandler(regex:String) {
        var index:Int = handlers.indexOf(regex);
        if (index != -1) {
            handlers.splice(index, 2);
        }
        return this;
    }

    public function getHandler(file:String):Dynamic {
        for (i in 0...handlers.length) {
            var regex:String = handlers[i];
            var loader:Dynamic = handlers[i + 1];
            if (regex != null && regex.global) regex.lastIndex = 0; // see #17920
            if (regex != null && regex.match(file) != null) {
                return loader;
            }
        }
        return null;
    }
}

@:final class DefaultLoadingManager {
    private static var instance:LoadingManager = new LoadingManager(null, null, null);

    public static function getInstance():LoadingManager {
        return instance;
    }
}