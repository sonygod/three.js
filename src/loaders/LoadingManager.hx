Here is the converted Haxe code:
```
package loaders;

class LoadingManager {
    public var onStart:Void->Void;
    public var onLoad:Void->Void;
    public var onProgress:String->Int->Int->Void;
    public var onError:String->Void;

    private var isLoading:Bool = false;
    private var itemsLoaded:Int = 0;
    private var itemsTotal:Int = 0;
    private var urlModifier:String->String;
    private var handlers:Array<Dynamic> = [];

    public function new(onLoad:Void->Void, onProgress:String->Int->Int->Void, onError:String->Void) {
        this.onLoad = onLoad;
        this.onProgress = onProgress;
        this.onError = onError;
    }

    public function itemStart(url:String):Void {
        itemsTotal++;
        if (!isLoading) {
            if (onStart != null) {
                onStart(url, itemsLoaded, itemsTotal);
            }
        }
        isLoading = true;
    }

    public function itemEnd(url:String):Void {
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

    public function itemError(url:String):Void {
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
        handlers.push(regex);
        handlers.push(loader);
        return this;
    }

    public function removeHandler(regex:EReg):LoadingManager {
        var index:Int = Lambda.indexOf(handlers, regex);
        if (index != -1) {
            handlers.splice(index, 2);
        }
        return this;
    }

    public function getHandler(file:String):Dynamic {
        for (i in 0...handlers.length) {
            var regex:EReg = handlers[i];
            var loader:Dynamic = handlers[i + 1];
            if (regex.global) regex.lastIndex = 0; // see #17920
            if (regex.match(file)) {
                return loader;
            }
        }
        return null;
    }
}

class DefaultLoadingManager extends LoadingManager {
    public function new() {
        super(null, null, null);
    }
}

// Export the classes
extern class LoadingManager {}
extern class DefaultLoadingManager {}
```
Note that I've used the `extern` keyword to declare the classes, as they are meant to be exported. I've also used the `Dynamic` type to represent the `loader` variable, as its type is not specified in the original JavaScript code. Additionally, I've used the `EReg` type to represent the regular expressions, which is the Haxe equivalent of JavaScript's `RegExp`.