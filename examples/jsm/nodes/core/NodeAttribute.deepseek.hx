class NodeAttribute {

    public var isNodeAttribute:Bool;
    public var name:String;
    public var type:String;
    public var node:Dynamic;

    public function new(name:String, type:String, ?node:Dynamic) {
        this.isNodeAttribute = true;
        this.name = name;
        this.type = type;
        this.node = node;
    }

}