package three.js.examples.jsm.loaders;

import three.animation.AnimationClip;
import three.animation.KeyframeTrack;
import three.animation.NumberKeyframeTrack;
import three.animation.QuaternionKeyframeTrack;
import three.animation.VectorKeyframeTrack;
import three.math.Euler;
import three.math.Quaternion;
import three.math.Vector3;

class AnimationBuilder {
    //...

    public function build(vmd:Dynamic, mesh:SkinnedMesh):AnimationClip {
        // Combine skeletal and morph animations
        var tracks:Array<KeyframeTrack> = buildSkeletalAnimation(vmd, mesh).tracks;
        var tracks2:Array<KeyframeTrack> = buildMorphAnimation(vmd, mesh).tracks;

        for (i in 0...tracks2.length) {
            tracks.push(tracks2[i]);
        }

        return new AnimationClip('', -1, tracks);
    }

    //...

    private function pushInterpolation(array:Array<Float>, interpolation:Array<Float>, index:Int) {
        array.push(interpolation[index + 0] / 127); // x1
        array.push(interpolation[index + 8] / 127); // x2
        array.push(interpolation[index + 4] / 127); // y1
        array.push(interpolation[index + 12] / 127); // y2
    }

    private function buildSkeletalAnimation(vmd:Dynamic, mesh:SkinnedMesh):AnimationClip {
        //...
    }

    private function buildMorphAnimation(vmd:Dynamic, mesh:SkinnedMesh):AnimationClip {
        //...
    }

    private function buildCameraAnimation(vmd:Dynamic):AnimationClip {
        //...
    }

    private function _createTrack(node:String, typedKeyframeTrack:Class<KeyframeTrack>, times:Array<Float>, values:Array<Float>, interpolations:Array<Float>):KeyframeTrack {
        //...
    }
}