package three.js.nodes.core;

class NodeFunctionInput {
    public var type:String;
    public var name:String;
    public var count:Null<Int>;
    public var qualifier:String;
    public var isConst:Bool;

    public function new(type:String, name:String, count:Null<Int> = null, qualifier:String = '', isConst:Bool = false) {
        this.type = type;
        this.name = name;
        this.count = count;
        this.qualifier = qualifier;
        this.isConst = isConst;
    }
}

class NodeFunctionInputMeta {
    public static inline var isNodeFunctionInput:Bool = true;
}

typedef NodeFunctionInput = NodeFunctionInputMeta;