import three.math.Color;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.core.FileLoader;
import three.core.Loader;
import three.math.Vector3;
import js.typedarrays.Float32Array;
import js.typedarrays.Int32Array;
import js.typedarrays.Uint8Array;
import js.typedarrays.Uint32Array;
import js.utils.TextDecoder;
import js.flash.utils.ByteArray;
import js.lib.fflate;

class VTKLoader extends Loader {

	public function new(manager:LoaderManager) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setResponseType("arraybuffer");
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(data:Dynamic) {
			try {
				onLoad(scope.parse(data));
			} catch(e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					trace(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(data:Dynamic):BufferGeometry {
		// Implement parsing logic here
	}

}