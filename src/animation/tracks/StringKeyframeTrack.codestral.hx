import animation.constants.InterpolateDiscrete;
import animation.KeyframeTrack;

class StringKeyframeTrack extends KeyframeTrack {
    public function new(name:String, times:Array<Float>, values:Array<String>) {
        super(name, times, values);
    }

    override public var ValueTypeName:String = "string";
    override public var ValueBufferType:Class<Array<dynamic>> = Array;
    override public var DefaultInterpolation:Int = InterpolateDiscrete;
    override public var InterpolantFactoryMethodLinear:Void = null;
    override public var InterpolantFactoryMethodSmooth:Void = null;
}