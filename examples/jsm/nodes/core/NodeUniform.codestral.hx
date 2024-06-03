class NodeUniform {

    public var isNodeUniform:Bool = true;
    public var name:String;
    public var type:Dynamic; // Assuming Dynamic is the equivalent of any type in JavaScript
    public var node:Node; // Assuming Node is a class or interface
    public var needsUpdate:Bool;

    public function new(name:String, type:Dynamic, node:Node, needsUpdate:Bool = null) {
        this.name = name;
        this.type = type;
        this.node = node.getSelf();
        this.needsUpdate = needsUpdate;
    }

    @:get('value')
    public function getValue():Dynamic {
        return this.node.value;
    }

    @:set('value')
    public function setValue(val:Dynamic):Void {
        this.node.value = val;
    }

    @:get('id')
    public function getId():Int {
        return this.node.id;
    }

    @:get('groupNode')
    public function getGroupNode():Node {
        return this.node.groupNode;
    }

}