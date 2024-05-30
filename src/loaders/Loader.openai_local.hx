import three.loaders.LoadingManager;

class Loader {

    public var manager:LoadingManager;
    public var crossOrigin:String;
    public var withCredentials:Bool;
    public var path:String;
    public var resourcePath:String;
    public var requestHeader:Map<String, String>;

    public static var DEFAULT_MATERIAL_NAME:String = '__DEFAULT';

    public function new(?manager:LoadingManager) {
        this.manager = if (manager != null) manager else DefaultLoadingManager;
        this.crossOrigin = 'anonymous';
        this.withCredentials = false;
        this.path = '';
        this.resourcePath = '';
        this.requestHeader = new Map<String, String>();
    }

    public function load(/* url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic */):Void {
        // Implement load logic here
    }

    public function loadAsync(url:String, onProgress:Dynamic):Promise<Dynamic> {
        var scope = this;
        return new Promise(function(resolve, reject) {
            scope.load(url, resolve, onProgress, reject);
        });
    }

    public function parse(/* data:Dynamic */):Void {
        // Implement parse logic here
    }

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

    public function setRequestHeader(requestHeader:Map<String, String>):Loader {
        this.requestHeader = requestHeader;
        return this;
    }

}