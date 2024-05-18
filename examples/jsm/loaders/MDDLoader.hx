package three.js.examples.jm.loaders;

import haxe.io.Bytes;
import haxe.io.BytesData;
import three.AnimationClip;
import three.BufferAttribute;
import three.FileLoader;
import three.Loader;
import three.NumberKeyframeTrack;

class MDDLoader extends Loader {
    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:(data:Any) -> Void, onProgress:(progress:Int) -> Void, onError:(error:Error) -> Void):Void {
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.load(url, function(data:Bytes) {
            onLoad(parse(data));
        }, onProgress, onError);
    }

    private function parse(data:Bytes):{ morphTargets:Array<BufferAttribute>, clip:AnimationClip } {
        var view:BytesData = BytesData.fromBytes(data);
        var totalFrames:Int = view.getUint32(0);
        var totalPoints:Int = view.getUint32(4);

        var offset:Int = 8;

        var times:Float32Array = new Float32Array(totalFrames);
        var values:Float32Array = new Float32Array(totalFrames * totalFrames);
        for (i in 0...totalFrames) {
            times[i] = view.getFloat32(offset);
            offset += 4;
            values[i * totalFrames + i] = 1;
        }

        var track:NumberKeyframeTrack = new NumberKeyframeTrack('.morphTargetInfluences', times, values);
        var clip:AnimationClip = new AnimationClip('default', times[totalFrames - 1], [track]);

        var morphTargets:Array<BufferAttribute> = [];
        for (i in 0...totalFrames) {
            var morphTarget:Float32Array = new Float32Array(totalPoints * 3);
            for (j in 0...totalPoints) {
                var stride:Int = j * 3;
                morphTarget[stride + 0] = view.getFloat32(offset);
                offset += 4;
                morphTarget[stride + 1] = view.getFloat32(offset);
                offset += 4;
                morphTarget[stride + 2] = view.getFloat32(offset);
                offset += 4;
            }
            var attribute:BufferAttribute = new BufferAttribute(morphTarget, 3);
            attribute.name = 'morph_' + i;
            morphTargets.push(attribute);
        }

        return { morphTargets: morphTargets, clip: clip };
    }
}