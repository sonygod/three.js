import haxe.ds.StringMap;
import js.html.FileLoader;
import js.typedarrays.Float32Array;
import js.typedarrays.Uint8Array;
import js.html.Element;
import js.html.Event;
import js.html.HTMLImageElement;
import js.html.HTMLAnchorElement;
import js.html.HTMLCanvasElement;
import js.html.HTMLVideoElement;
import js.html.HTMLParagraphElement;
import js.html.HTMLElement;
import js.html.Node;
import js.html.Document;
import js.Array;
import js.Boot;

class VRMLLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope = this;
		var path = (scope.path == '') ? LoaderUtils.extractUrlBase(url) : scope.path;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(text, path));
			} catch (e:Dynamic) {
				if (onError) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(data:String, path:String):Dynamic {
		// Implement the parse logic here
	}

}