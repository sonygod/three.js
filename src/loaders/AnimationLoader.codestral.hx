import three.animation.AnimationClip;
import three.loaders.FileLoader;
import three.loaders.Loader;

class AnimationLoader extends Loader{

    public function new(manager : Loader) {
        super(manager);
    }

    public function load(url : String, onLoad : Null<(Array<AnimationClip>) -> Void>, onProgress : Null<(Float) -> Void>, onError : Null<(Dynamic) -> Void>) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, (text : String) -> {
            try {
                onLoad(parse(haxe.Json.parse(text)));
            } catch (e : Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    haxe.Log.trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(json : haxe.Json.Value) : Array<AnimationClip> {
        var animations = new Array<AnimationClip>();
        for (i in 0...json.arr.length) {
            var clip = AnimationClip.parse(json.arr[i]);
            animations.push(clip);
        }
        return animations;
    }
}