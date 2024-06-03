import three.AnimationClip;
import three.BufferAttribute;
import three.FileLoader;
import three.Loader;
import three.NumberKeyframeTrack;

class MDDLoader extends Loader {
    public function new(manager:Loader.LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic -> Void, onProgress:(event:ProgressEvent) -> Void, onError:Dynamic -> Void):Void {
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.load(url, function(data:ArrayBuffer) {
            onLoad(this.parse(data));
        }, onProgress, onError);
    }

    public function parse(data:ArrayBuffer):Dynamic {
        var view:haxe.io.Bytes = haxe.io.Bytes.ofData(data);

        var totalFrames:Int = view.readUInt32();
        var totalPoints:Int = view.readUInt32();

        var offset:Int = 8;

        // animation clip

        var times:Float[] = [];
        var values:Float[] = [];

        for (i in 0...totalFrames) {
            times.push(view.readFloat(offset)); offset += 4;
            values.push(0);
            values[(totalFrames * i) + i] = 1;
        }

        var track:NumberKeyframeTrack = new NumberKeyframeTrack(".morphTargetInfluences", times, values);
        var clip:AnimationClip = new AnimationClip("default", times[times.length - 1], [track]);

        // morph targets

        var morphTargets:Array<BufferAttribute> = [];

        for (i in 0...totalFrames) {
            var morphTarget:Float[] = [];

            for (j in 0...totalPoints) {
                morphTarget.push(view.readFloat(offset)); offset += 4; // x
                morphTarget.push(view.readFloat(offset)); offset += 4; // y
                morphTarget.push(view.readFloat(offset)); offset += 4; // z
            }

            var attribute:BufferAttribute = new BufferAttribute(morphTarget, 3);
            attribute.name = "morph_" + i;

            morphTargets.push(attribute);
        }

        return {
            morphTargets: morphTargets,
            clip: clip
        };
    }
}

class Main {
    static function main() {
        // usage
        var mddLoader:MDDLoader = new MDDLoader(null);
        mddLoader.load("path/to/file", function(result) {
            // do something with result.morphTargets and result.clip
        }, null, null);
    }
}