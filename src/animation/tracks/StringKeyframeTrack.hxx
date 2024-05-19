import three.js.src.constants.InterpolateDiscrete;
import three.js.src.animation.tracks.KeyframeTrack;

/**
 * A Track that interpolates Strings
 */
class StringKeyframeTrack extends KeyframeTrack {

	// No interpolation parameter because only InterpolateDiscrete is valid.
	public function new(name:String, times:Array<Float>, values:Array<String>) {
		super(name, times, values);
	}

}

StringKeyframeTrack.ValueTypeName = 'string';
StringKeyframeTrack.ValueBufferType = Array;
StringKeyframeTrack.DefaultInterpolation = InterpolateDiscrete;
StringKeyframeTrack.InterpolantFactoryMethodLinear = null;
StringKeyframeTrack.InterpolantFactoryMethodSmooth = null;