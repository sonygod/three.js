class NodeFunctionInput {
    public var type:Dynamic;
    public var name:String;
    public var count:Null<Dynamic>;
    public var qualifier:String;
    public var isConst:Bool;

    public function new(type:Dynamic, name:String, count:Null<Dynamic> = null, qualifier:String = "", isConst:Bool = false) {
        this.type = type;
        this.name = name;
        this.count = count;
        this.qualifier = qualifier;
        this.isConst = isConst;
    }

    public static var isNodeFunctionInput(v:Dynamic):Bool {
        return Type.getClass(v) == Type.getClass(new NodeFunctionInput());
    }
}