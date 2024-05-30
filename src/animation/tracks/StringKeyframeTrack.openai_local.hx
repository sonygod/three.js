import three.constants.InterpolateDiscrete;
import three.animation.tracks.KeyframeTrack;

/**
 * A Track that interpolates Strings
 */
class StringKeyframeTrack extends KeyframeTrack {

	// No interpolation parameter because only InterpolateDiscrete is valid.
	public function new(name:String, times:Array<Float>, values:Array<String>) {
		super(name, times, values);
	}

	static public var ValueTypeName:String = 'string';
	static public var ValueBufferType:Dynamic = Array; // Haxe doesn't have direct equivalent to JavaScript's Array type
	static public var DefaultInterpolation = InterpolateDiscrete;
	static public var InterpolantFactoryMethodLinear:Dynamic = null;
	static public var InterpolantFactoryMethodSmooth:Dynamic = null;
}