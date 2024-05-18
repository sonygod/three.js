package three.loaders;

import three.audio.AudioContext;
import three.loaders.FileLoader;
import three.loaders.Loader;

class AudioLoader extends Loader {

    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:AudioBuffer->Void, onProgress:ProgressEvent->Void, onError:Error->Void) {
        var loader = new FileLoader(this.manager);
        loader.setResponseType('arraybuffer');
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(buffer:ArrayBuffer) {
            try {
                var bufferCopy = buffer.slice(0);
                var context = AudioContext.getContext();
                context.decodeAudioData(bufferCopy, function(audioBuffer:AudioBuffer) {
                    onLoad(audioBuffer);
                }).catchError(function(e:Error) {
                    handleError(e);
                });
            } catch (e:Error) {
                handleError(e);
            }
        }, onProgress, onError);
    }

    private function handleError(e:Error) {
        if (onError != null) {
            onError(e);
        } else {
            trace(e);
        }
        this.manager.itemError(url);
    }
}