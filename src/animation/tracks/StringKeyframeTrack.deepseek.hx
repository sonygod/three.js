import three.js.src.constants.InterpolateDiscrete;
import three.js.src.animation.KeyframeTrack;

/**
 * A Track that interpolates Strings
 */
class StringKeyframeTrack extends KeyframeTrack {

	// No interpolation parameter because only InterpolateDiscrete is valid.
	public function new(name:String, times:Array<Float>, values:Array<String>) {
		super(name, times, values);
	}

	public static var ValueTypeName:String = 'string';
	public static var ValueBufferType:Class<Array> = Array;
	public static var DefaultInterpolation:InterpolateDiscrete = InterpolateDiscrete;
	public static var InterpolantFactoryMethodLinear:Void = null;
	public static var InterpolantFactoryMethodSmooth:Void = null;

}