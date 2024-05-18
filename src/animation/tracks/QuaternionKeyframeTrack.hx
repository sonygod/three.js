package three.animation.tracks;

import three.animation.KeyframeTrack;
import three.math.interpolants.QuaternionLinearInterpolant;

/**
 * A Track of quaternion keyframe values.
 */
class QuaternionKeyframeTrack extends KeyframeTrack {

    public function new() {
        super();
    }

    public function InterpolantFactoryMethodLinear(result:Dynamic) {
        return new QuaternionLinearInterpolant(times, values, getValueSize(), result);
    }

    static public var ValueTypeName:String = 'quaternion';
    // ValueBufferType is inherited
    // DefaultInterpolation is inherited;
    static public var InterpolantFactoryMethodSmooth:Null<Dynamic> = null;
}