class NodeFunctionInput {

    public var type:String;
    public var name:String;
    public var count:Int;
    public var qualifier:String;
    public var isConst:Bool;

    public function new(type:String, name:String, ?count:Int = null, ?qualifier:String = '', ?isConst:Bool = false) {
        this.type = type;
        this.name = name;
        this.count = count;
        this.qualifier = qualifier;
        this.isConst = isConst;
    }

    static public var isNodeFunctionInput:Bool = true;

}