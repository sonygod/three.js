import threejs.loaders.LoadingManager;

class Loader {

    public static var DEFAULT_MATERIAL_NAME:String = "__DEFAULT";

    public var manager:LoadingManager;
    public var crossOrigin:String;
    public var withCredentials:Bool;
    public var path:String;
    public var resourcePath:String;
    public var requestHeader:Dynamic;

    public function new(manager:LoadingManager = null) {
        this.manager = (manager != null) ? manager : DefaultLoadingManager;
        this.crossOrigin = 'anonymous';
        this.withCredentials = false;
        this.path = '';
        this.resourcePath = '';
        this.requestHeader = {};
    }

    public function load(/* url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic */) {}

    public function loadAsync(url:String, onProgress:Dynamic):Promise<Dynamic> {
        var scope = this;

        return new Promise(function(resolve, reject) {
            scope.load(url, resolve, onProgress, reject);
        });
    }

    public function parse(/* data:Dynamic */) {}

    public function setCrossOrigin(crossOrigin:String):Loader {
        this.crossOrigin = crossOrigin;
        return this;
    }

    public function setWithCredentials(value:Bool):Loader {
        this.withCredentials = value;
        return this;
    }

    public function setPath(path:String):Loader {
        this.path = path;
        return this;
    }

    public function setResourcePath(resourcePath:String):Loader {
        this.resourcePath = resourcePath;
        return this;
    }

    public function setRequestHeader(requestHeader:Dynamic):Loader {
        this.requestHeader = requestHeader;
        return this;
    }
}