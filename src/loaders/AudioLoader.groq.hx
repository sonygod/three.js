package three.loaders;

import three.audio.AudioContext;
import three.loaders.FileLoader;
import three.loaders.Loader;

class AudioLoader extends Loader {

    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:AudioBuffer->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope:AudioLoader = this;
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setResponseType('arraybuffer');
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(buffer:Dynamic) {
            try {
                // Create a copy of the buffer. The `decodeAudioData` method
                // detaches the buffer when complete, preventing reuse.
                var bufferCopy:ArrayBuffer = buffer.slice(0);
                var context:AudioContext = AudioContext.getContext();
                context.decodeAudioData(bufferCopy, function(audioBuffer:AudioBuffer) {
                    onLoad(audioBuffer);
                }).catchError(function(e:Dynamic) {
                    handleError(e);
                });
            } catch (e:Dynamic) {
                handleError(e);
            }
        }, onProgress, onError);
    }

    private function handleError(e:Dynamic):Void {
        if (onError != null) {
            onError(e);
        } else {
            trace(e);
        }
        this.manager.itemError(url);
    }
}