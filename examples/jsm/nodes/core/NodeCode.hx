package three.js.examples.jsm.nodes.core;

class NodeCode {
    public var name:String;
    public var type:String;
    public var code:String;
    public var isNodeCode:Bool;

    public function new(name:String, type:String, code:String = '') {
        this.name = name;
        this.type = type;
        this.code = code;
        this.isNodeCode = true;
    }
}