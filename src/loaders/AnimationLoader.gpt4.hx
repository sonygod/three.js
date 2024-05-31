import threejs.animation.AnimationClip;
import threejs.loaders.FileLoader;
import threejs.loaders.Loader;

class AnimationLoader extends Loader {

    public function new(manager:Dynamic) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String):Void {
            try {
                onLoad(scope.parse(haxe.Json.parse(text)));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(json:Dynamic):Array<Dynamic> {
        var animations:Array<Dynamic> = [];
        for (i in 0...json.length) {
            var clip = AnimationClip.parse(json[i]);
            animations.push(clip);
        }
        return animations;
    }

    public static function main() {
        // Example usage
        var manager = {}; // Substitute with actual manager object
        var loader = new AnimationLoader(manager);
        loader.load("path/to/animation.json", function(animations) {
            trace("Loaded animations: " + animations);
        }, function(progress) {
            trace("Progress: " + progress);
        }, function(error) {
            trace("Error: " + error);
        });
    }
}