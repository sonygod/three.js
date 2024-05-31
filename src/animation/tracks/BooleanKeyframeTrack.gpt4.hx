import three.constants.InterpolateDiscrete;
import three.animation.KeyframeTrack;

/**
 * A Track of Boolean keyframe values.
 */
class BooleanKeyframeTrack extends KeyframeTrack {

    // No interpolation parameter because only InterpolateDiscrete is valid.
    public function new(name:String, times:Array<Float>, values:Array<Bool>) {
        super(name, times, values);
    }

    // Define the static properties as class-level variables
    public static var ValueTypeName:String = 'bool';
    public static var ValueBufferType:Class<Dynamic> = Array;
    public static var DefaultInterpolation:Int = InterpolateDiscrete;
    public static var InterpolantFactoryMethodLinear:Null<Dynamic> = null;
    public static var InterpolantFactoryMethodSmooth:Null<Dynamic> = null;
}

// Note: Actually this track could have a optimized / compressed
// representation of a single value and a custom interpolant that
// computes "firstValue ^ isOdd( index )".