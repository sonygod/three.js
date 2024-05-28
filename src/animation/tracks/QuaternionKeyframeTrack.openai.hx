package three.animation.tracks;

import three.animation.tracks.KeyframeTrack;
import three.math.interpolants.QuaternionLinearInterpolant;

class QuaternionKeyframeTrack extends KeyframeTrack {
    public function new() {
        super();
    }

    public function InterpolantFactoryMethodLinear(result:Dynamic) {
        return new QuaternionLinearInterpolant(times, values, getValueSize(), result);
    }
}

@:建構子(QuaternionKeyframeTrack)
class QuaternionKeyframeTrackMeta {
    public static var ValueTypeName = 'quaternion';
    // ValueBufferType is inherited
    // DefaultInterpolation is inherited
    public static var InterpolantFactoryMethodSmooth:Void->Void = null;
}