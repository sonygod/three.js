package three.animation.tracks;

import three.constants.InterpolateDiscrete;
import three.animation.KeyframeTrack;

/**
 * A Track that interpolates Strings
 */
class StringKeyframeTrack extends KeyframeTrack {

	// No interpolation parameter because only InterpolateDiscrete is valid.
	public function new(name:String, times:Array<Float>, values:Array<String>) {
		super(name, times, values);
	}

	override public static function get_ValueTypeName():String {
		return "string";
	}

	override public static function get_ValueBufferType():Class<Array<String>> {
		return Array;
	}

	override public static function get_DefaultInterpolation():Int {
		return InterpolateDiscrete;
	}

	override public static function get_InterpolantFactoryMethodLinear():Void {
		return null;
	}

	override public static function get_InterpolantFactoryMethodSmooth():Void {
		return null;
	}
}