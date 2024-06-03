import KeyframeTrack from "../KeyframeTrack";
import QuaternionLinearInterpolant from "../../math/interpolants/QuaternionLinearInterpolant";

/**
 * A Track of quaternion keyframe values.
 */
class QuaternionKeyframeTrack extends KeyframeTrack {

	public function new() {
		super();
	}

	override function InterpolantFactoryMethodLinear(result:Dynamic):QuaternionLinearInterpolant {
		return new QuaternionLinearInterpolant(this.times, this.values, this.getValueSize(), result);
	}

}

QuaternionKeyframeTrack.ValueTypeName = "quaternion";
// ValueBufferType is inherited
// DefaultInterpolation is inherited;
QuaternionKeyframeTrack.InterpolantFactoryMethodSmooth = null;

export default QuaternionKeyframeTrack;