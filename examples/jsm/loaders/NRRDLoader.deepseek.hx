import three.FileLoader;
import three.Loader;
import three.Matrix4;
import three.Vector3;
import fflate.gunzipSync;
import three.misc.Volume;

class NRRDLoader extends Loader {

	public function new(manager:LoaderManager) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(data:ArrayBuffer) {
			try {
				onLoad(scope.parse(data));
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

	public function setSegmentation(segmentation:Bool):Void {
		this.segmentation = segmentation;
	}

	public function parse(data:ArrayBuffer):Volume {
		// ... (rest of the code)
	}

	// ... (rest of the code)
}

// ... (rest of the code)