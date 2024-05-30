class ProgrammableStage {
    public static var _id:Int = 0;

    public var id:Int;
    public var code:String;
    public var stage:String;
    public var transforms:Null<Dynamic>;
    public var attributes:Null<Dynamic>;
    public var usedTimes:Int;

    public function new(code:String, type:String, transforms:Null<Dynamic> = null, attributes:Null<Dynamic> = null) {
        this.id = _id++;
        this.code = code;
        this.stage = type;
        this.transforms = transforms;
        this.attributes = attributes;
        this.usedTimes = 0;
    }
}