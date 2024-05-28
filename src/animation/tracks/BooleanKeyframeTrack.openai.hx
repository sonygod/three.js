package three.animation.tracks;

import three.animation.tracks.KeyframeTrack;
import three.constants.InterpolateDiscrete;

/**
 * A Track of Boolean keyframe values.
 */
class BooleanKeyframeTrack extends KeyframeTrack {
    public function new(name:String, times:Array<Float>, values:Array<Bool>) {
        super(name, times, values);
    }
}

@:nativeGen
class BooleanKeyframeTrack {
    public static var ValueTypeName:String = 'bool';
    public static var ValueBufferType:Array<Bool> = Array;
    public static var DefaultInterpolation:Int = InterpolateDiscrete;
    public static var InterpolantFactoryMethodLinear:Null<Void->Void> = null;
    public static var InterpolantFactoryMethodSmooth:Null<Void->Void> = null;
}