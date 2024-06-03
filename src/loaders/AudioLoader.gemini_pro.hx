import haxe.io.Bytes;
import js.html.AudioContext;
import js.html.File;
import js.html.FileReader;
import js.html.URL;
import js.html.Window;

class AudioLoader extends Loader {

	public function new(manager:LoaderManager) {
		super(manager);
	}

	public function load(url:String, onLoad:AudioBuffer->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var loader = new FileLoader(manager);
		loader.setResponseType("arraybuffer");
		loader.setPath(path);
		loader.setRequestHeader(requestHeader);
		loader.setWithCredentials(withCredentials);
		loader.load(url, function(buffer:Bytes) {
			try {
				var bufferCopy = buffer.slice(0);
				var context = AudioContext.getContext();
				context.decodeAudioData(bufferCopy, function(audioBuffer:AudioBuffer) {
					onLoad(audioBuffer);
				}, handleError);
			} catch (e:Dynamic) {
				handleError(e);
			}
		}, onProgress, onError);

		function handleError(e:Dynamic):Void {
			if (onError != null) {
				onError(e);
			} else {
				Sys.println(e);
			}
			manager.itemError(url);
		}
	}
}