import js.html.AudioContext;
import threejs.loaders.FileLoader;
import threejs.loaders.Loader;

class AudioLoader extends Loader {

    public function new(manager:Dynamic) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;

        var loader = new FileLoader(this.manager);
        loader.setResponseType('arraybuffer');
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(buffer:haxe.io.Bytes):Void {

            try {
                // Create a copy of the buffer. The `decodeAudioData` method
                // detaches the buffer when complete, preventing reuse.
                var bufferCopy = buffer.slice(0, buffer.length);

                var context = AudioContext.getContext();
                context.decodeAudioData(bufferCopy, function(audioBuffer:Dynamic):Void {
                    onLoad(audioBuffer);
                }).catch(handleError);

            } catch (e:Dynamic) {
                handleError(e);
            }

        }, onProgress, onError);

        function handleError(e:Dynamic):Void {
            if (onError != null) {
                onError(e);
            } else {
                trace(e);
            }
            scope.manager.itemError(url);
        }
    }
}

@:expose('AudioLoader')
class ExportAudioLoader {
    public static function create(manager:Dynamic):AudioLoader {
        return new AudioLoader(manager);
    }
}