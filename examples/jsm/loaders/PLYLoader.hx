import three.loaders.Loader;
import three.loaders.FileLoader;
import three.math.Color;

class PLYLoader extends Loader {
	public var propertyNameMapping:Dict<String>;
	public var customPropertyMapping:Dict<Array<String>>;

	public function new(manager:Loader.Manager) {
		super(manager);
		propertyNameMapping = new Dict<String>();
		customPropertyMapping = new Dict<Array<String>>();
	}

	//... other methods from the JavaScript code

	// Example of a method
	public override function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		// ... implementation of the method
	}
}

// Helper class
class ArrayStream {
	private var _arr:Array<Dynamic>;
	private var _i:Int;

	public function new(arr:Array<Dynamic>) {
		_arr = arr;
		_i = 0;
	}

	public function empty():Bool {
		return _i >= _arr.length;
	}

	public function next():Dynamic {
		return _arr[_i++];
	}
}

// Export the class
export class PLYLoader;