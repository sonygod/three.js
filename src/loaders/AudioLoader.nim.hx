import three.audio.AudioContext;
import three.loaders.FileLoader;
import three.loaders.Loader;

class AudioLoader extends Loader {

	public function new(manager:Loader.Manager) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
		var scope = this;

		var loader = new FileLoader(this.manager);
		loader.setResponseType("arraybuffer");
		loader.setPath(this.path);
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(buffer:ArrayBuffer) {
			try {
				// Create a copy of the buffer. The `decodeAudioData` method
				// detaches the buffer when complete, preventing reuse.
				var bufferCopy = buffer.slice(0);

				var context = AudioContext.getContext();
				context.decodeAudioData(bufferCopy, function(audioBuffer:AudioBuffer) {
					onLoad(audioBuffer);
				}).catch(handleError);
			} catch (e:Dynamic) {
				handleError(e);
			}
		}, onProgress, onError);

		function handleError(e:Dynamic) {
			if (onError != null) {
				onError(e);
			} else {
				trace(e);
			}
			scope.manager.itemError(url);
		}
	}
}

export class Main {
	static function main() {
		var loader = new AudioLoader(null);
	}
}