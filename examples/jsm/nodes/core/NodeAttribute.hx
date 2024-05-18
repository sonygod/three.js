package three.js.examples.jsm.nodes.core;

class NodeAttribute {
    public var isNodeAttribute:Bool = true;

    public var name:String;
    public var type:Dynamic;
    public var node:Node;

    public function new(name:String, type:Dynamic, ?node:Node = null) {
        this.name = name;
        this.type = type;
        this.node = node;
    }
}