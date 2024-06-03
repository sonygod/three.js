class ProgrammableStage {
    private static var _id: Int = 0;

    public var id: Int;
    public var code: String;
    public var stage: String;
    public var transforms: Array<Dynamic>;
    public var attributes: Map<String, Dynamic>;
    public var usedTimes: Int;

    public function new(code: String, type: String, transforms: Array<Dynamic> = null, attributes: Map<String, Dynamic> = null) {
        this.id = _id++;
        this.code = code;
        this.stage = type;
        this.transforms = transforms;
        this.attributes = attributes;
        this.usedTimes = 0;
    }
}

export default ProgrammableStage;