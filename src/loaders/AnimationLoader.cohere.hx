package;

import js.Browser.XmlHttp;
import js.Browser.XmlHttpRequest;
import js.Browser.XmlHttpProgressEvent;
import js.Browser.Window;
import js.html.FormData;
import js.html.FormDataEvent;
import js.html.DataTransfer;
import js.html.DataTransferItemList;
import js.html.File;
import js.html.FileList;
import js.html.Blob;
import js.html.BlobEvent;
import js.html.MediaError;
import js.html.TimeRanges;
import js.html.AudioContext;
import js.html.AudioNode;
import js.html.AudioParam;
import jsMultiplier.animation.AnimationClip;
import jsMultiplier.loaders.FileLoader;
import jsMultiplier.loaders.Loader;

class AnimationLoader extends Loader {
	public function new(manager:Dynamic) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var loader = new FileLoader(manager);
		loader.path = path;
		loader.requestHeader = requestHeader;
		loader.withCredentials = withCredentials;
		loader.load(url, function(text) {
			try {
				onLoad(scope.parse(Std.jsonParse(text)));
			} catch( e:Dynamic ) {
				if (onError != null) {
					onError(e);
				} else {
					trace(e);
					manager.itemError(url);
				}
			}
		}, onProgress, onError);
	}

	public function parse(json:Dynamic):Array<AnimationClip> {
		var animations = [];
		for (i in 0...json.length) {
			var clip = AnimationClip.parse(json[i]);
			animations.push(clip);
		}
		return animations;
	}
}