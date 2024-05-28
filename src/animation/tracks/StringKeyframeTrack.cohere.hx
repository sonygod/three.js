class StringKeyframeTrack extends KeyframeTrack {
    public function new(name:String, times:Array<Float>, values:Array<String>) {
        super(name, times, values);
    }

    public static var ValueTypeName:String = 'string';
    public static var ValueBufferType:Class<Dynamic> = Array;
    public static var DefaultInterpolation:Int = InterpolateDiscrete;
    public static var InterpolantFactoryMethodLinear:Dynamic = null;
    public static var InterpolantFactoryMethodSmooth:Dynamic = null;
}