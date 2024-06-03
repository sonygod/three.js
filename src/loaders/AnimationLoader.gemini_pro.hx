import animation.AnimationClip;
import haxe.io.Bytes;
import haxe.io.StringTools;
import haxe.io.File;
import haxe.io.Path;
import haxe.io.BytesInput;
import haxe.Json;
import haxe.ds.StringMap;

class AnimationLoader extends Loader {

  public function new(manager : LoaderManager) {
    super(manager);
  }

  public function load(url : String, onLoad : AnimationClip -> Void, onProgress : Bytes -> Void, onError : Dynamic -> Void) {
    var scope = this;
    var loader = new FileLoader(manager);
    loader.setPath(path);
    loader.setRequestHeader(requestHeader);
    loader.setWithCredentials(withCredentials);
    loader.load(url, function(bytes : Bytes) {
      try {
        var json = Json.parse(Bytes.toString(bytes));
        onLoad(parse(json));
      } catch (e : Dynamic) {
        if (onError != null) {
          onError(e);
        } else {
          Sys.println(e);
        }
        manager.itemError(url);
      }
    }, onProgress, onError);
  }

  public function parse(json : Dynamic) : Array<AnimationClip> {
    var animations = new Array<AnimationClip>();
    for (i in 0...json.length) {
      animations.push(AnimationClip.parse(json[i]));
    }
    return animations;
  }

}