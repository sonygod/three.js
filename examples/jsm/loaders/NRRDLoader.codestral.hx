import js.Browser.window;

class NRRDLoader {

    public var segmentation:Bool;
    public var manager:Object; // replace Object with appropriate type

    public function new(manager:Object) { // replace Object with appropriate type
        this.manager = manager;
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var scope = this;
        var loader = js.Browser.window.FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(data) {
            try {
                onLoad(scope.parse(data));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    js.Browser.window.console.error(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function setSegmentation(segmentation:Bool) {
        this.segmentation = segmentation;
    }

    public function parse(data:Dynamic) {
        // Implementation of parse function...
    }

    public function parseChars(array:Dynamic, start:Int, end:Int):String {
        // Implementation of parseChars function...
    }
}

var _fieldFunctions = {
    // Implementation of _fieldFunctions object...
};

// Export the NRRDLoader class
js.Browser.window.NRRDLoader = NRRDLoader;