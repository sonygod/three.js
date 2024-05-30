import three.js.examples.jsm.loaders.PLYLoader;
import three.js.examples.jsm.loaders.FileLoader;
import three.js.examples.jsm.loaders.Loader;
import three.js.examples.jsm.math.Color;
import three.js.examples.jsm.core.BufferGeometry;
import three.js.examples.jsm.core.Float32BufferAttribute;

class Main {
  static function main() {
    var loader = new PLYLoader();
    loader.load('./models/ply/ascii/dolphins.ply', function(geometry) {
      scene.add(new three.Mesh(geometry));
    });
  }
}

class PLYLoader extends Loader {
  var propertyNameMapping: Dynamic;
  var customPropertyMapping: Dynamic;

  public function new(manager:Loader.LoaderManager) {
    super(manager);
    this.propertyNameMapping = {};
    this.customPropertyMapping = {};
  }

  public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
    var scope = this;
    var loader = new FileLoader(this.manager);
    loader.setPath(this.path);
    loader.setResponseType('arraybuffer');
    loader.setRequestHeader(this.requestHeader);
    loader.setWithCredentials(this.withCredentials);
    loader.load(url, function(text) {
      try {
        onLoad(scope.parse(text));
      } catch (e:Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          trace(e);
        }
        scope.manager.itemError(url);
      }
    }, onProgress, onError);
  }

  public function setPropertyNameMapping(mapping:Dynamic) {
    this.propertyNameMapping = mapping;
  }

  public function setCustomPropertyNameMapping(mapping:Dynamic) {
    this.customPropertyMapping = mapping;
  }

  public function parse(data:Dynamic) {
    // ...
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