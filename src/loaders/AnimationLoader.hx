package three.loaders;

import three.animation.AnimationClip;
import three.loaders.FileLoader;
import three.loaders.Loader;

class AnimationLoader extends Loader {
    
    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:(animations:Array<AnimationClip>)->Void, onProgress:(ProgressBar:Float)->Void, onError:(error:Dynamic)->Void):Void {
        var loader = new FileLoader(manager);
        loader.setPath(path);
        loader.setRequestHeader(requestHeader);
        loader.setWithCredentials(withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(parse(JSON.parse(text)));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(json:Array<Dynamic>):Array<AnimationClip> {
        var animations:Array<AnimationClip> = [];
        for (i in 0...json.length) {
            var clip = AnimationClip.parse(json[i]);
            animations.push(clip);
        }
        return animations;
    }
}