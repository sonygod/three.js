class ProgrammableStage {

	public var id:Int;
	public var code:String;
	public var stage:String;
	public var transforms:Dynamic;
	public var attributes:Dynamic;
	public var usedTimes:Int;

	static var _id:Int = 0;

	public function new(code:String, stage:String, transforms:Dynamic = null, attributes:Dynamic = null) {
		this.id = _id++;
		this.code = code;
		this.stage = stage;
		this.transforms = transforms;
		this.attributes = attributes;
		this.usedTimes = 0;
	}

}