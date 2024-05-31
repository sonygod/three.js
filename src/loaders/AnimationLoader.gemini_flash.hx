import three.animation.AnimationClip;
import three.loaders.FileLoader;
import three.loaders.Loader;

class AnimationLoader extends Loader {
	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:AnimationClip->Void, onProgress:(Float->Void), onError:(Dynamic->Void)) {
		var scope = this;
		var loader = new FileLoader(manager);
		loader.setPath(path);
		loader.setRequestHeader(requestHeader);
		loader.setWithCredentials(withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(js.JSON.parse(text)));
			} catch(e:Dynamic) {
				if(onError != null) {
					onError(e);
				} else {
					js.Lib.console.error(e);
				}
				manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(json:Dynamic):Array<AnimationClip> {
		var animations:Array<AnimationClip> = new Array<AnimationClip>();
		for(i in 0...json.length) {
			var clip = AnimationClip.parse(json[i]);
			animations.push(clip);
		}
		return animations;
	}
}