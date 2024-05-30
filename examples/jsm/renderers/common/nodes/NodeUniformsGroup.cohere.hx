class NodeUniformsGroup extends UniformsGroup {
	public var id:Int;
	public var groupNode:Group;

	public function new(name:String, groupNode:Group) {
		super(name);
		id = 0;
		self.id = id++;
		self.groupNode = groupNode;
	}

	public function get shared():Bool {
		return groupNode.shared;
	}

	public function getNodes():Array<Node> {
		var nodes = [];
		for (uniform in uniforms) {
			var node = uniform.nodeUniform.node;
			if (node == null) {
				throw "NodeUniformsGroup: Uniform has no node.";
			}
			nodes.push(node);
		}
		return nodes;
	}
}