import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Loader;

class VTKLoader extends Loader {

	public function new(manager:Loader.Manager) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
		var scope = this;

		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setResponseType("arraybuffer");
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text) {
			try {
				onLoad(scope.parse(text));
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

	public function parse(data:Dynamic) {
		function parseASCII(data:Dynamic) {
			// ...
		}

		function parseBinary(data:Dynamic) {
			// ...
		}

		function Float32Concat(first:Dynamic, second:Dynamic) {
			// ...
		}

		function Int32Concat(first:Dynamic, second:Dynamic) {
			// ...
		}

		function parseXML(stringFile:Dynamic) {
			// ...
		}

		var textDecoder = new TextDecoder();

		// get the 5 first lines of the files to check if there is the key word binary
		var meta = textDecoder.decode(new Uint8Array(data, 0, 250)).split("\n");

		if (meta[0].indexOf("xml") !== -1) {
			return parseXML(textDecoder.decode(data));
		} else if (meta[2].includes("ASCII")) {
			return parseASCII(textDecoder.decode(data));
		} else {
			return parseBinary(data);
		}
	}
}