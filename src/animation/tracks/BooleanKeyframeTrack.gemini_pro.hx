import constants.InterpolateDiscrete;
import KeyframeTrack from "../KeyframeTrack";

/**
 * A Track of Boolean keyframe values.
 */
class BooleanKeyframeTrack extends KeyframeTrack {

	// No interpolation parameter because only InterpolateDiscrete is valid.
	public function new(name:String, times:Array<Float>, values:Array<Bool>) {
		super(name, times, values);
	}

}

BooleanKeyframeTrack.ValueTypeName = "bool";
BooleanKeyframeTrack.ValueBufferType = Array;
BooleanKeyframeTrack.DefaultInterpolation = InterpolateDiscrete;
BooleanKeyframeTrack.InterpolantFactoryMethodLinear = null;
BooleanKeyframeTrack.InterpolantFactoryMethodSmooth = null;

// Note: Actually this track could have a optimized / compressed
// representation of a single value and a custom interpolant that
// computes "firstValue ^ isOdd( index )".

class BooleanKeyframeTrack {
	static public var ValueTypeName:String = "bool";
	static public var ValueBufferType:Dynamic = Array;
	static public var DefaultInterpolation:Int = InterpolateDiscrete;
	static public var InterpolantFactoryMethodLinear:Dynamic = null;
	static public var InterpolantFactoryMethodSmooth:Dynamic = null;
}