class ProgrammableStage {

    static var _id:Int = 0;

    var id:Int;
    var code:String;
    var stage:String;
    var transforms:Array<Dynamic>;
    var attributes:Array<Dynamic>;
    var usedTimes:Int;

    public function new(code:String, type:String, transforms:Array<Dynamic> = null, attributes:Array<Dynamic> = null) {
        this.id = _id ++;
        this.code = code;
        this.stage = type;
        this.transforms = transforms;
        this.attributes = attributes;
        this.usedTimes = 0;
    }

}