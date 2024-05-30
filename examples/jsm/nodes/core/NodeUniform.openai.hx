package three.js.examples.jsm.nodes.core;

class NodeUniform {
    public var isNodeUniform:Bool = true;

    public var name:String;
    public var type:String;
    public var node:Dynamic;
    public var needsUpdate:Bool;

    public function new(name:String, type:String, node:Dynamic, needsUpdate:Bool = false) {
        this.name = name;
        this.type = type;
        this.node = node.getSelf();
        this.needsUpdate = needsUpdate;
    }

    public var value(get, set):Dynamic;

    private function get_value():Dynamic {
        return node.value;
    }

    private function set_value(val:Dynamic):Dynamic {
        node.value = val;
        return val;
    }

    public var id(get, never):Int;

    private function get_id():Int {
        return node.id;
    }

    public var groupNode(get, never):Dynamic;

    private function get_groupNode():Dynamic {
        return node.groupNode;
    }
}