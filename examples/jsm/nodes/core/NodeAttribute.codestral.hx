import haxe.ds.StringMap;

class NodeAttribute {
    public var isNodeAttribute:Bool = true;
    public var name:String;
    public var type:String;
    public var node:Dynamic;

    public function new(name:String, type:String, ?node:Dynamic) {
        this.name = name;
        this.type = type;
        this.node = node != null ? node : null;
    }
}

export default NodeAttribute;