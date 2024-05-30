import three.examples.jsm.loaders.FileLoader;
import three.examples.jsm.loaders.Loader;
import three.examples.jsm.math.Matrix4;
import three.examples.jsm.math.Vector3;
import three.examples.jsm.misc.Volume;

class NRRDLoader extends Loader {

	public function new(manager:Loader.LoaderManager) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
		var scope = this;

		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setResponseType("arraybuffer");
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(data) {
			try {
				onLoad(scope.parse(data));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					Sys.println(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function setSegmentation(segmentation:Bool) {
		this.segmentation = segmentation;
	}

	private function parse(data:haxe.io.Bytes) {
		// ...
	}

	private function parseChars(array:haxe.io.Bytes, start:Int, end:Int) {
		// ...
	}
}

class _fieldFunctions {
	public static function type(data:String):String {
		// ...
	}

	public static function endian(data:String):String {
		// ...
	}

	public static function encoding(data:String):String {
		// ...
	}

	public static function dimension(data:String):Int {
		// ...
	}

	public static function sizes(data:String):Array<Int> {
		// ...
	}

	public static function space(data:String):String {
		// ...
	}

	public static function spaceOrigin(data:String):Array<String> {
		// ...
	}

	public static function spaceDirections(data:String):Array<Array<Float>> {
		// ...
	}

	public static function spacing(data:String):Array<Float> {
		// ...
	}
}