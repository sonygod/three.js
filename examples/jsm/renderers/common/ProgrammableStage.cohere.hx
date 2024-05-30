var _id:Int = 0;

class ProgrammableStage {
	public id:Int;
	public var code:String;
	public var stage:String;
	public var transforms:Null<Array<String>>;
	public var attributes:Null<Dynamic>;
	public var usedTimes:Int;

	public function new(code:String, type:String, ?transforms:Array<String>, ?attributes:Dynamic) {
		this.id = _id++;
		this.code = code;
		this.stage = type;
		this.transforms = transforms;
		this.attributes = attributes;
		this.usedTimes = 0;
	}
}