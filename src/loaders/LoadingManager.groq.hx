package three.loaders;

import haxe.ds.ArraySlice;

class LoadingManager {
    public var onStart:Void->Void;
    public var onLoad:Void->Void;
    public var onProgress:String->Int->Int->Void;
    public var onError:String->Void;

    private var isLoading:Bool = false;
    private var itemsLoaded:Int = 0;
    private var itemsTotal:Int = 0;
    private var urlModifier:String->String;
    private var handlers:Array<Array<Dynamic>> = [];

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

    public function addHandler(regex:EReg, loader:Dynamic):LoadingManager {
        handlers.push([regex, loader]);
        return this;
    }

    public function removeHandler(regex:EReg):LoadingManager {
        var index = Lambda.indexOf(helpers, regex);
        if (index != -1) {
            handlers.splice(index, 2);
        }
        return this;
    }

    public function getHandler(file:String):Dynamic {
        for (i in 0...handlers.length) {
            var regex = handlers[i][0];
            var loader = handlers[i][1];
            if (regex.match(file)) {
                return loader;
            }
        }
        return null;
    }
}

class DefaultLoadingManager {
    public static var instance:LoadingManager = new LoadingManager(null, null, null);
}