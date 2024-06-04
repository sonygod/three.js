import Node from "./Node";
import ShaderNode from "../shadernode/ShaderNode";

class VarNode extends Node {

	public var node:Node;
	public var name:String;

	public var isVarNode:Bool = true;

	public function new(node:Node, name:String = null) {
		super();
		this.node = node;
		this.name = name;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function getHash(builder:ShaderNode):String {
		return this.name != null ? this.name : super.getHash(builder);
	}

	public function getNodeType(builder:ShaderNode):ShaderNode.NodeType {
		return this.node.getNodeType(builder);
	}

	public function generate(builder:ShaderNode):String {
		var node = this.node;
		var name = this.name;

		var nodeVar = builder.getVarFromNode(this, name, builder.getVectorType(this.getNodeType(builder)));
		var propertyName = builder.getPropertyName(nodeVar);
		var snippet = node.build(builder, nodeVar.type);

		builder.addLineFlowCode("$propertyName = $snippet");
		return propertyName;
	}

}

export var temp:ShaderNode.Proxy = ShaderNode.proxy(VarNode);

ShaderNode.addNodeElement("temp", temp); // @TODO: Will be removed in the future
ShaderNode.addNodeElement("toVar", function(...params:Dynamic):ShaderNode.Proxy {
	return temp(...params).append();
});

ShaderNode.addNodeClass("VarNode", VarNode);