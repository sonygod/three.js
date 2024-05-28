package three.animation.tracks;

import three.constants.InterpolateDiscrete;
import three.animation.tracks.KeyframeTrack;

/**
 * A Track of Boolean keyframe values.
 */
class BooleanKeyframeTrack extends KeyframeTrack {

	// No interpolation parameter because only InterpolateDiscrete is valid.
	public function new(name:String, times:Array<Float>, values:Array<Bool>) {
		super(name, times, values);
	}

	public static var ValueTypeName:String = 'bool';
	public static var ValueBufferType:Array<Bool> = Array;
	public static var DefaultInterpolation:Int = InterpolateDiscrete;
	public static var InterpolantFactoryMethodLinear:Null<Void->Void> = null;
	public static var InterpolantFactoryMethodSmooth:Null<Void->Void> = null;

}

// Note: Actually this track could have a optimized / compressed
// representation of a single value and a custom interpolant that
// computes "firstValue ^ isOdd( index )".

// Export the class
extern class BooleanKeyframeTrack {}