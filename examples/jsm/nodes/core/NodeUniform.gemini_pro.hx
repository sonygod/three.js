class NodeUniform {

	public var isNodeUniform:Bool = true;

	public var name:String;
	public var type:String;
	public var node:Dynamic;
	public var needsUpdate:Dynamic;

	public function new(name:String, type:String, node:Dynamic, needsUpdate:Dynamic = null) {
		this.name = name;
		this.type = type;
		this.node = node.getSelf();
		this.needsUpdate = needsUpdate;
	}

	public function get_value():Dynamic {
		return this.node.value;
	}

	public function set_value(val:Dynamic):Dynamic {
		this.node.value = val;
		return val;
	}

	public function get_id():Dynamic {
		return this.node.id;
	}

	public function get_groupNode():Dynamic {
		return this.node.groupNode;
	}

}