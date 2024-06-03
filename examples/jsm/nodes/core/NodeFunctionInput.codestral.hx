class NodeFunctionInput {
    public var type: Dynamic;
    public var name: String;
    public var count: Int;
    public var qualifier: String;
    public var isConst: Bool;

    public function new(type: Dynamic, name: String, count: Int = null, qualifier: String = '', isConst: Bool = false) {
        this.type = type;
        this.name = name;
        this.count = count;
        this.qualifier = qualifier;
        this.isConst = isConst;
    }
}

NodeFunctionInput.isNodeFunctionInput = true;