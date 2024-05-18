package three.animation.tracks;

import three.constants.InterpolateDiscrete;
import three.animation.tracks.KeyframeTrack;

/**
 * A Track that interpolates Strings
 */
class StringKeyframeTrack extends KeyframeTrack {

    public function new(name:String, times:Array<Float>, values:Array<String>) {
        super(name, times, values);
    }

    static public var ValueTypeName:String = 'string';
    static public var ValueBufferType:Array<String> = Array;
    static public var DefaultInterpolation:InterpolateDiscrete = InterpolateDiscrete;
    static public var InterpolantFactoryMethodLinear:Null<Dynamic> = null;
    static public var InterpolantFactoryMethodSmooth:Null<Dynamic> = null;
}