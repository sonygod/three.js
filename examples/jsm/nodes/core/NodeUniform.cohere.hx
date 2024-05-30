class NodeUniform {
	public var isNodeUniform:Bool = true;
	public var name:String;
	public var type:Dynamic;
	public var node:Dynamic;
	public var needsUpdate:Bool;

	public function new(name:String, type:Dynamic, node:Dynamic, ?needsUpdate:Bool) {
		this.name = name;
		this.type = type;
		this.node = node;
		this.needsUpdate = needsUpdate ?? undefined;
	}

	public function getValue():Dynamic {
		return node.value;
	}

	public function setValue(val:Dynamic):Void {
		node.value = val;
	}

	public function getId():Int {
		return node.id;
	}

	public function getGroupNode():Dynamic {
		return node.groupNode;
	}
}

class Export {
	public static function get_default():Dynamic {
		return NodeUniform;
	}
}