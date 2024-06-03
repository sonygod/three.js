import three.js.loaders.LoadingManager;

class Loader {

    var manager: LoadingManager;
    var crossOrigin: String;
    var withCredentials: Bool;
    var path: String;
    var resourcePath: String;
    var requestHeader: haxe.ds.StringMap<String>;

    public function new(?manager: LoadingManager) {
        if (manager != null) {
            this.manager = manager;
        } else {
            this.manager = LoadingManager.DefaultLoadingManager;
        }
        this.crossOrigin = 'anonymous';
        this.withCredentials = false;
        this.path = '';
        this.resourcePath = '';
        this.requestHeader = new haxe.ds.StringMap();
    }

    public function load(url: String, onLoad: Null<(data: Dynamic) -> Void>, onProgress: Null<(event: ProgressEvent) -> Void>, onError: Null<(event: Dynamic) -> Void>): Void {
        // Implementation goes here
    }

    public function loadAsync(url: String, onProgress: Null<(event: ProgressEvent) -> Void>): Promise<Dynamic> {
        return new Promise((resolve, reject) -> {
            this.load(url, resolve, onProgress, reject);
        });
    }

    public function parse(data: Dynamic): Dynamic {
        // Implementation goes here
        return null;
    }

    public function setCrossOrigin(crossOrigin: String): Loader {
        this.crossOrigin = crossOrigin;
        return this;
    }

    public function setWithCredentials(value: Bool): Loader {
        this.withCredentials = value;
        return this;
    }

    public function setPath(path: String): Loader {
        this.path = path;
        return this;
    }

    public function setResourcePath(resourcePath: String): Loader {
        this.resourcePath = resourcePath;
        return this;
    }

    public function setRequestHeader(requestHeader: haxe.ds.StringMap<String>): Loader {
        this.requestHeader = requestHeader;
        return this;
    }
}

class Loader_ {
    public static var DEFAULT_MATERIAL_NAME: String = '__DEFAULT';
}