package three.js.examples.jvm.nodes.core;

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

    private var _value:Dynamic;
    public var value(get, set):Dynamic;

    private function get_value():Dynamic {
        return node.value;
    }

    private function set_value(val:Dynamic):Dynamic {
        node.value = val;
        return val;
    }

    private var _id:Dynamic;
    public var id(get, never):Dynamic;

    private function get_id():Dynamic {
        return node.id;
    }

    private var _groupNode:Dynamic;
    public var groupNode(get, never):Dynamic;

    private function get_groupNode():Dynamic {
        return node.groupNode;
    }
}