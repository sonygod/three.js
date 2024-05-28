import js.Browser.Window;

class BooleanKeyframeTrack extends KeyframeTrack {
    public function new(name:String, times:Array<Float>, values:Array<Bool>) {
        super(name, times, values);
    }

    static public var ValueTypeName:String = 'bool';
    static public var ValueBufferType:Array<Bool>;
    static public var DefaultInterpolation:Int = InterpolateDiscrete;
    static public var InterpolantFactoryMethodLinear:Dynamic = null;
    static public var InterpolantFactoryMethodSmooth:Dynamic = null;
}

class KeyframeTrack {
    public var name:String;
    public var times:Array<Float>;
    public var values:Dynamic;

    public function new(name:String, times:Array<Float>, values:Dynamic) {
        this.name = name;
        this.times = times;
        this.values = values;
    }
}

class InterpolateDiscrete {
    public static var name:String = "InterpolateDiscrete";
    public static var index:Int = 0;
}