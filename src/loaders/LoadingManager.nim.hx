class LoadingManager {
    public var onStart:Dynamic;
    public var onLoad:Dynamic;
    public var onProgress:Dynamic;
    public var onError:Dynamic;

    private var isLoading:Bool;
    private var itemsLoaded:Int;
    private var itemsTotal:Int;
    private var urlModifier:Dynamic;
    private var handlers:Array<Dynamic>;

    public function new(onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        this.onStart = null;
        this.onLoad = onLoad;
        this.onProgress = onProgress;
        this.onError = onError;

        this.isLoading = false;
        this.itemsLoaded = 0;
        this.itemsTotal = 0;
        this.urlModifier = null;
        this.handlers = [];
    }

    public function itemStart(url:String) {
        this.itemsTotal++;

        if (this.isLoading == false) {
            if (this.onStart != null) {
                this.onStart(url, this.itemsLoaded, this.itemsTotal);
            }
        }

        this.isLoading = true;
    }

    public function itemEnd(url:String) {
        this.itemsLoaded++;

        if (this.onProgress != null) {
            this.onProgress(url, this.itemsLoaded, this.itemsTotal);
        }

        if (this.itemsLoaded == this.itemsTotal) {
            this.isLoading = false;

            if (this.onLoad != null) {
                this.onLoad();
            }
        }
    }

    public function itemError(url:String) {
        if (this.onError != null) {
            this.onError(url);
        }
    }

    public function resolveURL(url:String) {
        if (this.urlModifier != null) {
            return this.urlModifier(url);
        }

        return url;
    }

    public function setURLModifier(transform:Dynamic) {
        this.urlModifier = transform;
        return this;
    }

    public function addHandler(regex:Dynamic, loader:Dynamic) {
        this.handlers.push(regex, loader);
        return this;
    }

    public function removeHandler(regex:Dynamic) {
        var index = this.handlers.indexOf(regex);

        if (index != -1) {
            this.handlers.splice(index, 2);
        }

        return this;
    }

    public function getHandler(file:String) {
        for (i in 0...this.handlers.length by 2) {
            var regex = this.handlers[i];
            var loader = this.handlers[i + 1];

            if (regex.global) regex.lastIndex = 0;

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

export class LoadingManager;
export class DefaultLoadingManager;