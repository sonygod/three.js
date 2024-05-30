import three.BufferGeometry;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Loader;
import three.Color;

class PLYLoader extends Loader {

    var propertyNameMapping:Map<String, String>;
    var customPropertyMapping:Map<String, Array<String>>;

    public function new(manager:LoaderManager) {
        super(manager);
        propertyNameMapping = new Map<String, String>();
        customPropertyMapping = new Map<String, Array<String>>();
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:LoaderProgress->Void, onError:Dynamic->Void) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function (text) {
            try {
                onLoad(this.parse(text));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function setPropertyNameMapping(mapping:Map<String, String>) {
        propertyNameMapping = mapping;
    }

    public function setCustomPropertyNameMapping(mapping:Map<String, Array<String>>) {
        customPropertyMapping = mapping;
    }

    public function parse(data:String) {
        // TODO: Implement parse function
        return null;
    }
}

class ArrayStream {

    var arr:Array<Dynamic>;
    var i:Int;

    public function new(arr:Array<Dynamic>) {
        this.arr = arr;
        this.i = 0;
    }

    public function empty():Bool {
        return this.i >= this.arr.length;
    }

    public function next():Dynamic {
        return this.arr[this.i++];
    }
}