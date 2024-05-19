import InterpolateDiscrete from '../../constants';
import KeyframeTrack from '../KeyframeTrack';

/**
 * A Track of Boolean keyframe values.
 */
class BooleanKeyframeTrack extends KeyframeTrack {

    public function new(name:String, times:Array<Float>, values:Array<Bool>) {
        super(name, times, values);
    }

}

BooleanKeyframeTrack.ValueTypeName = 'bool';
BooleanKeyframeTrack.ValueBufferType = Array<Bool>;
BooleanKeyframeTrack.DefaultInterpolation = InterpolateDiscrete;
BooleanKeyframeTrack.InterpolantFactoryMethodLinear = null;
BooleanKeyframeTrack.InterpolantFactoryMethodSmooth = null;

// Note: Actually this track could have a optimized / compressed
// representation of a single value and a custom interpolant that
// computes "firstValue ^ isOdd( index )".