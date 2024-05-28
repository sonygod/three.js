import js.html.AudioContext;
import js.html.AudioBuffer;
import js.html.ErrorEvent;

import js.openfl.FileLoader;
import js.openfl.events.Event;
import js.openfl.net.URLRequest;
import js.openfl.net.URLRequestMethod;

class AudioLoader extends js.openfl.display.Loader {
    public function new(manager:Dynamic) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(this.manager);
        loader.set_responseType("arraybuffer");
        loader.set_path(this.path);
        loader.set_requestHeader(this.requestHeader);
        loader.set_withCredentials(this.withCredentials);
        loader.addEventListener(Event.COMPLETE, function(e:Event) {
            var buffer = cast loader.data;
            var context = AudioContext.getContext();
            try {
                var bufferCopy = buffer.slice(0, buffer.byteLength);
                context.decodeAudioData(bufferCopy, function(audioBuffer:AudioBuffer) {
                    onLoad(audioBuffer);
                });
            } catch(e:Dynamic) {
                handleError(cast e);
            }
        });
        loader.addEventListener(Event.ERROR, function(e:Event) {
            handleError(cast e.target.data);
        });
        loader.load(new URLRequest(url));

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

class AudioContext {
    public static function getContext():AudioContext {
        return js.Browser.window.AudioContext.create();
    }
}