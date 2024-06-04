import Node from "../core/Node";

class ArrayElementNode extends Node {

	public var node:Node;
	public var indexNode:Node;

	public function new(node:Node, indexNode:Node) {
		super();
		this.node = node;
		this.indexNode = indexNode;
		this.isArrayElementNode = true;
	}

	public function getNodeType(builder:Dynamic):Dynamic {
		return this.node.getNodeType(builder);
	}

	public function generate(builder:Dynamic):String {
		var nodeSnippet = this.node.build(builder);
		var indexSnippet = this.indexNode.build(builder, "uint");
		return "${nodeSnippet}[ ${indexSnippet} ]";
	}

}

// TODO: Implement addNodeClass equivalent in Haxe
// For now, you can manually register the class in your main file:
// Node.addNodeClass("ArrayElementNode", ArrayElementNode);

export default ArrayElementNode;