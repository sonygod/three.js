import InterpolateDiscrete from '../../constants.js';
import KeyframeTrack from '../KeyframeTrack.js';

/**
 * A Track that interpolates Strings
 */
class StringKeyframeTrack extends KeyframeTrack {

	// No interpolation parameter because only InterpolateDiscrete is valid.
	public function new(name:String, times:Array<Dynamic>, values:Array<Dynamic>) {

		super(name, times, values);

	}

}

StringKeyframeTrack.prototype.ValueTypeName = 'string';
StringKeyframeTrack.prototype.ValueBufferType = Array;
StringKeyframeTrack.prototype.DefaultInterpolation = InterpolateDiscrete;
StringKeyframeTrack.prototype.InterpolantFactoryMethodLinear = null;
StringKeyframeTrack.prototype.InterpolantFactoryMethodSmooth = null;

export default StringKeyframeTrack;