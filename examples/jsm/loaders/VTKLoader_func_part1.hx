import js.Date;
import js.typedarray.ArrayBuffer;
import js.typedarray.DataView;
import js.typedarray.Uint8Array;
import js.typedarray.Float32Array;
import js.typedarray.Int32Array;
import js.lib.fflate;
import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.FileLoader;
import three.Loader;
import three.LoaderUtils;

class VTKLoader extends Loader {

	public function new(manager:Loader.Manager) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text:ArrayBuffer) {
			try {
				onLoad(scope.parse(text));
			} catch(e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					Sys.printLine("Error: " + Std.string(e));
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(data:ArrayBuffer):BufferGeometry {
		function parseASCII(data:ArrayBuffer):BufferGeometry {
			// ... (the same as in the JavaScript code)
		}

		function parseBinary(data:ArrayBuffer):BufferGeometry {
			// ... (the same as in the JavaScript code)
		}

		function parseXML(stringFile:String):BufferGeometry {
			// ... (the same as in the JavaScript code)
		}

		var textDecoder = new TextDecoder();
		// get the 5 first lines of the files to check if there is the key word binary
		var meta = textDecoder.decode( new Uint8Array( data, 0, 250 ) ).split('\n');

		if (meta[0].indexOf('xml') != -1) {
			return parseXML(textDecoder.decode(data));
		} else if (meta[2].includes('ASCII')) {
			return parseASCII(textDecoder.decode(data));
		} else {
			return parseBinary(data);
		}
	}

}