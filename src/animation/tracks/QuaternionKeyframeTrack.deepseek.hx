import three.js.src.animation.tracks.KeyframeTrack;
import three.js.src.math.interpolants.QuaternionLinearInterpolant;

/**
 * A Track of quaternion keyframe values.
 */
class QuaternionKeyframeTrack extends KeyframeTrack {

	public function new(times:Array<Float>, values:Array<Float>, interpolation:String = "undefined") {
		super(times, values, interpolation);
	}

	override public function InterpolantFactoryMethodLinear(result:Array<Float>):QuaternionLinearInterpolant {
		return new QuaternionLinearInterpolant(this.times, this.values, this.getValueSize(), result);
	}

	static public var ValueTypeName:String = 'quaternion';
	// ValueBufferType is inherited
	// DefaultInterpolation is inherited;
	static public var InterpolantFactoryMethodSmooth:Void = null;

}