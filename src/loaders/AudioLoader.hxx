import js.Browser.AudioContext;
import js.Browser.FileLoader;
import js.Browser.Loader;

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
        loader.load(url, function(buffer:Dynamic) {
            try {
                var bufferCopy = buffer.slice(0);

                var context = AudioContext.getContext();
                context.decodeAudioData(bufferCopy, function(audioBuffer:Dynamic) {
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
                js.Browser.console.error(e);
            }

            scope.manager.itemError(url);
        }
    }
}