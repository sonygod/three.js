class Loader {
    public var manager:DefaultLoadingManager;
    public var crossOrigin:String;
    public var withCredentials:Bool;
    public var path:String;
    public var resourcePath:String;
    public var requestHeader:Map<String,String>;

    public function new(manager:DefaultLoadingManager = null) {
        this.manager = manager != null ? manager : DefaultLoadingManager;
        this.crossOrigin = "anonymous";
        this.withCredentials = false;
        this.path = "";
        this.resourcePath = "";
        this.requestHeader = new Map<String,String>();
    }

    public function loadAsync(url:String, onProgress:Dynamic -> Void):Future<Void> {
        var scope = this;
        return future(function(completer) {
            scope.load(url, completer.complete, onProgress, completer.error);
        });
    }

    public function setCrossOrigin(crossOrigin:String):Void {
        this.crossOrigin = crossOrigin;
    }

    public function setWithCredentials(value:Bool):Void {
        this.withCredentials = value;
    }

    public function setPath(path:String):Void {
        this.path = path;
    }

    public function setResourcePath(resourcePath:String):Void {
        this.resourcePath = resourcePath;
    }

    public function setRequestHeader(requestHeader:Map<String,String>):Void {
        this.requestHeader = requestHeader;
    }

    static public var DEFAULT_MATERIAL_NAME:String = "__DEFAULT";
}