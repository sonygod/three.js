package three.loaders;

import audio.AudioContext;
import three.loaders.FileLoader;
import three.loaders.Loader;

class AudioLoader extends Loader {
    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:(audioBuffer:js.lib.ArrayBuffer)->Void, onProgress:(progress:Float)->Void, onError:(error:Dynamic)->Void):Void {
        var loader = new FileLoader(this.manager);
        loader.setResponseType('arraybuffer');
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(buffer:js.lib.ArrayBuffer) {
            try {
                var bufferCopy = buffer.slice(0);
                var context = AudioContext.getContext();
                context.decodeAudioData(bufferCopy, function(audioBuffer) {
                    onLoad(audioBuffer);
                }).catchError(function(e) {
                    handleError(e);
                });
            } catch (e:Dynamic) {
                handleError(e);
            }
        }, onProgress, onError);
    }

    private function handleError(e:Dynamic) {
        if (onError != null) {
            onError(e);
        } else {
            trace(e);
        }
        this.manager.itemError(url);
    }
}