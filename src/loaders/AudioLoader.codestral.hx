import js.html.AudioContext;
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
                js.Browser.console.error(e);
            }
            scope.manager.itemError(url);
        }
    }
}