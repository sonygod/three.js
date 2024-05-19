import three.js.src.constants.InterpolateDiscrete;
import three.js.src.animation.tracks.KeyframeTrack;

/**
 * A Track of Boolean keyframe values.
 */
class BooleanKeyframeTrack extends KeyframeTrack {

	// No interpolation parameter because only InterpolateDiscrete is valid.
	public function new(name:String, times:Array<Float>, values:Array<Bool>) {
		super(name, times, values);
	}

}

BooleanKeyframeTrack.ValueTypeName = 'bool';
BooleanKeyframeTrack.ValueBufferType = Array;
BooleanKeyframeTrack.DefaultInterpolation = InterpolateDiscrete;
BooleanKeyframeTrack.InterpolantFactoryMethodLinear = null;
BooleanKeyframeTrack.InterpolantFactoryMethodSmooth = null;

// Note: Actually this track could have a optimized / compressed
// representation of a single value and a custom interpolant that
// computes "firstValue ^ isOdd( index )".