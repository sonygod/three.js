import UniformsGroup from "../UniformsGroup";

class NodeUniformsGroup extends UniformsGroup {

	public static id:Int = 0;

	public id:Int;
	public groupNode:Dynamic;
	public isNodeUniformsGroup:Bool = true;

	public function new(name:String, groupNode:Dynamic) {
		super(name);
		this.id = NodeUniformsGroup.id++;
		this.groupNode = groupNode;
	}

	public function get_shared():Bool {
		return this.groupNode.shared;
	}

	public function getNodes():Array<Dynamic> {
		var nodes:Array<Dynamic> = [];
		for (uniform in this.uniforms) {
			var node = uniform.nodeUniform.node;
			if (node == null) throw "NodeUniformsGroup: Uniform has no node.";
			nodes.push(node);
		}
		return nodes;
	}

}