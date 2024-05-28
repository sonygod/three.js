package three.loaders;

import three.loaders.LoadingManager.DefaultLoadingManager;

class Loader {
    public var manager:LoadingManager;
    public var crossOrigin:String;
    public var withCredentials:Bool;
    public var path:String;
    public var resourcePath:String;
    public var requestHeader:Dynamic;

    public function new(?manager:LoadingManager) {
        this.manager = (manager != null) ? manager : DefaultLoadingManager;
        this.crossOrigin = 'anonymous';
        this.withCredentials = false;
        this.path = '';
        this.resourcePath = '';
        this.requestHeader = {};
    }

    public function load(/* url, onLoad, onProgress, onError */):Void {}

    public function loadAsync(url:String, onProgress:Dynamic->Void):Promise<Dynamic> {
        var scope:Loader = this;
        return new Promise(function(resolve:Dynamic->Void, reject:Dynamic->Void) {
            scope.load(url, resolve, onProgress, reject);
        });
    }

    public function parse(/* data */):Void {}

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

    public static inline var DEFAULT_MATERIAL_NAME:String = '__DEFAULT';
}