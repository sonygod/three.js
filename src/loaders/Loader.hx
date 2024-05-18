package loaders;

import three.loaders.DefaultLoadingManager;

class Loader {
    public var manager:DefaultLoadingManager;
    public var crossOrigin:String;
    public var withCredentials:Bool;
    public var path:String;
    public var resourcePath:String;
    public var requestHeader:Dynamic;

    public function new(?manager:DefaultLoadingManager) {
        this.manager = (manager != null) ? manager : DefaultLoadingManager.getInstance();
        this.crossOrigin = 'anonymous';
        this.withCredentials = false;
        this.path = '';
        this.resourcePath = '';
        this.requestHeader = {};
    }

    public function load(/* url, onLoad, onProgress, onError */) {}

    public function loadAsync(url:String, onProgress:Dynamic):Promise<Void> {
        var scope = this;
        return Promise.create(function(resolve, reject) {
            scope.load(url, resolve, onProgress, reject);
        });
    }

    public function parse(/* data */) {}

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