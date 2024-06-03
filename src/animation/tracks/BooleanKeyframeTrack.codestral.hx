import three.animation.KeyframeTrack;

/**
 * A Track of Boolean keyframe values.
 */
class BooleanKeyframeTrack extends KeyframeTrack {

	// No interpolation parameter because only InterpolateDiscrete is valid.
	public function new(name: String, times: Array<Float>, values: Array<Bool>) {
		super(name, times, values);
	}

	override public var ValueTypeName: String = "bool";
	override public var ValueBufferType: Class<Dynamic> = Array;
	override public var DefaultInterpolation: Int = InterpolateDiscrete;
	override public var InterpolantFactoryMethodLinear: Null<Void> = null;
	override public var InterpolantFactoryMethodSmooth: Null<Void> = null;
}

// Note: Actually this track could have a optimized / compressed
// representation of a single value and a custom interpolant that
// computes "firstValue ^ isOdd( index )".