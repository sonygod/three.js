package three.animation.tracks;

import three.constants.InterpolateDiscrete;
import three.animation.KeyframeTrack;

/**
 * A Track that interpolates Strings
 */
class StringKeyframeTrack extends KeyframeTrack {

    public function new(name:String, times:Array<Float>, values:Array<String>) {
        super(name, times, values);
    }

    public static var ValueTypeName:String = 'string';
    public static var ValueBufferType:Array<String> = Array;
    public static var DefaultInterpolation:Int = InterpolateDiscrete;
    public static var InterpolantFactoryMethodLinear:Void->Void = null;
    public static var InterpolantFactoryMethodSmooth:Void->Void = null;
}