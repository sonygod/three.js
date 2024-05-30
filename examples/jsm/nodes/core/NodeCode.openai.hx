package three.js.examples.jvm.nodes.core;

class NodeCode {
    public var name:String;
    public var type:String;
    public var code:String;

    public function new(name:String, type:String, code:String = '') {
        this.name = name;
        this.type = type;
        this.code = code;
    }

    private static var isNodeCode:Bool = true;
}