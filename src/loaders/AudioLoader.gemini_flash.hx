import three.audio.AudioContext;
import three.loaders.FileLoader;
import three.loaders.Loader;

class AudioLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:(audioBuffer:haxe.io.Bytes) -> Void, onProgress:(event:Dynamic) -> Void, onError:(event:Dynamic) -> Void):Void {
		var scope = this;
		var loader = new FileLoader(this.manager);
		loader.setResponseType("arraybuffer");
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(buffer:haxe.io.Bytes) {
			try {
				// Create a copy of the buffer. The `decodeAudioData` method
				// detaches the buffer when complete, preventing reuse.
				var bufferCopy = buffer.slice(0);

				var context = AudioContext.getContext();
				context.decodeAudioData(bufferCopy, function(audioBuffer:haxe.io.Bytes) {
					onLoad(audioBuffer);
				}, handleError);

			} catch (e) {
				handleError(e);
			}
		}, onProgress, onError);

		function handleError(e:Dynamic) {
			if (onError != null) {
				onError(e);
			} else {
				Sys.println(e);
			}
			scope.manager.itemError(url);
		}
	}

}