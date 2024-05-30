class ProgrammableStage {
  static var _id:Int = 0;

  public var id(default, null):Int;
  public var code:String;
  public var stage:String;
  public var transforms:Null<Array<Transform>>;
  public var attributes:Null<Array<Dynamic>>;

  public var usedTimes:Int;

  public function new(code:String, stage:String, ?transforms:Array<Transform>, ?attributes:Array<Dynamic>) {
    id = _id++;
    this.code = code;
    this.stage = stage;
    this.transforms = transforms;
    this.attributes = attributes;
    this.usedTimes = 0;
  }
}