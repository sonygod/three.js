import three.animation.KeyframeTrack;
import three.math.interpolants.QuaternionLinearInterpolant;

/**
 * A Track of quaternion keyframe values.
 */
class QuaternionKeyframeTrack extends KeyframeTrack {

	public function new() {
		super();
		this.ValueTypeName = "quaternion";
	}

	override public function InterpolantFactoryMethodLinear(result:Dynamic):QuaternionLinearInterpolant {
		return new QuaternionLinearInterpolant(this.times, this.values, this.getValueSize(), result);
	}

}