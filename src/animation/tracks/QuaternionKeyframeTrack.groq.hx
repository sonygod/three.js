package three.animation.tracks;

import three.KeyframeTrack;
import three.math.interpolants.QuaternionLinearInterpolant;

/**
 * A Track of quaternion keyframe values.
 */
class QuaternionKeyframeTrack extends KeyframeTrack {
    override function InterpolantFactoryMethodLinear(result:Dynamic):Void {
        return new QuaternionLinearInterpolant(times, values, getValueSize(), result);
    }

    static public var ValueTypeName:String = 'quaternion';
    // ValueBufferType is inherited
    // DefaultInterpolation is inherited
    static public var InterpolantFactoryMethodSmooth:Dynamic = null;
}