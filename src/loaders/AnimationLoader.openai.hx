package three.loaders;

import three.animation.AnimationClip;
import three.loaders.FileLoader;
import three.loaders.Loader;

class AnimationLoader extends Loader {
    public function new(manager:Dynamic) {
        super(manager);
    }

    public function load(url:String, onLoad:Void->Void, onProgress:Float->Void, onError:Dynamic->Void) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(parse(Json.parse(text)));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function parse(json:Array<Dynamic>) {
        var animations:Array<AnimationClip> = [];
        for (i in 0...json.length) {
            var clip:AnimationClip = AnimationClip.parse(json[i]);
            animations.push(clip);
        }
        return animations;
    }
}