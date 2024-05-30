package three.js.loaders;

import three.js.animation.AnimationClip;
import three.js.animation.NumberKeyframeTrack;
import three.js.core.BufferAttribute;
import three.js.loaders.FileLoader;
import three.js.loaders.Loader;

class MDDLoader extends Loader {
    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:Array<Any> -> Void, onProgress:Float -> Void, onError:String -> Void) {
        var loader = new FileLoader(manager);
        loader.setPath(path);
        loader.setResponseType('arraybuffer');
        loader.load(url, function(data:ArrayBuffer) {
            onLoad([parse(data)]);
        }, onProgress, onError);
    }

    private function parse(data:ArrayBuffer):{ morphTargets:Array<BufferAttribute>, clip:AnimationClip } {
        var view = new DataView(data);
        var totalFrames = view.getUint32(0);
        var totalPoints = view.getUint32(4);
        var offset = 8;

        // animation clip
        var times = new Float32Array(totalFrames);
        var values = new Float32Array(totalFrames * totalFrames);
        for (i in 0...totalFrames) {
            times[i] = view.getFloat32(offset); offset += 4;
            values[totalFrames * i + i] = 1;
        }
        var track = new NumberKeyframeTrack('.morphTargetInfluences', times, values);
        var clip = new AnimationClip('default', times[totalFrames - 1], [track]);

        // morph targets
        var morphTargets = [];
        for (i in 0...totalFrames) {
            var morphTarget = new Float32Array(totalPoints * 3);
            for (j in 0...totalPoints) {
                var stride = j * 3;
                morphTarget[stride + 0] = view.getFloat32(offset); offset += 4; // x
                morphTarget[stride + 1] = view.getFloat32(offset); offset += 4; // y
                morphTarget[stride + 2] = view.getFloat32(offset); offset += 4; // z
            }
            var attribute = new BufferAttribute(morphTarget, 3);
            attribute.name = 'morph_' + i;
            morphTargets.push(attribute);
        }

        return { morphTargets: morphTargets, clip: clip };
    }
}