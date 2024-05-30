import InterpolateDiscrete from '../../constants.js';
import KeyframeTrack from '../KeyframeTrack.js';

/**
 * A Track of Boolean keyframe values.
 */
class BooleanKeyframeTrack extends KeyframeTrack {

	// No interpolation parameter because only InterpolateDiscrete is valid.
	public function new(name:String, times:Array<Dynamic>, values:Array<Dynamic>) {

		super(name, times, values);

	}

}

BooleanKeyframeTrack.prototype.ValueTypeName = 'bool';
BooleanKeyframeTrack.prototype.ValueBufferType = Array;
BooleanKeyframeTrack.prototype.DefaultInterpolation = InterpolateDiscrete;
BooleanKeyframeTrack.prototype.InterpolantFactoryMethodLinear = null;
BooleanKeyframeTrack.prototype.InterpolantFactoryMethodSmooth = null;

// Note: Actually this track could have a optimized / compressed
// representation of a single value and a custom interpolant that
// computes "firstValue ^ isOdd( index )".

export default BooleanKeyframeTrack;