import KeyframeTrack from '../KeyframeTrack.hx';
import QuaternionLinearInterpolant from '../../math/interpolants/QuaternionLinearInterpolant.hx';

/**
 * A Track of quaternion keyframe values.
 */
class QuaternionKeyframeTrack extends KeyframeTrack {

    public function new() {
        super();
    }

    public function InterpolantFactoryMethodLinear(result:Dynamic) {
        return new QuaternionLinearInterpolant(this.times, this.values, this.getValueSize(), result);
    }

    public static var ValueTypeName(default, null) = 'quaternion';
    // ValueBufferType is inherited
    // DefaultInterpolation is inherited;
    public static var InterpolantFactoryMethodSmooth(default, null) = null;

}

export QuaternionKeyframeTrack;