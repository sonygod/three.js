class NodeUniform {

    public var isNodeUniform:Bool;
    public var name:String;
    public var type:String;
    public var node:Dynamic;
    public var needsUpdate:Dynamic;

    public function new(name:String, type:String, node:Dynamic, needsUpdate:Dynamic = null) {
        this.isNodeUniform = true;
        this.name = name;
        this.type = type;
        this.node = node.getSelf();
        this.needsUpdate = needsUpdate;
    }

    public function get value():Dynamic {
        return this.node.value;
    }

    public function set value(val:Dynamic):Void {
        this.node.value = val;
    }

    public function get id():Dynamic {
        return this.node.id;
    }

    public function get groupNode():Dynamic {
        return this.node.groupNode;
    }

}