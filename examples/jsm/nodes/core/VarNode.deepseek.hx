import Node;
import ShaderNode;

class VarNode extends Node {

	public function new(node:Node, name:String = null) {
		super();
		this.node = node;
		this.name = name;
		this.isVarNode = true;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function getHash(builder:ShaderNode.Builder):String {
		return this.name != null ? this.name : super.getHash(builder);
	}

	public function getNodeType(builder:ShaderNode.Builder):String {
		return this.node.getNodeType(builder);
	}

	public function generate(builder:ShaderNode.Builder):String {
		var nodeVar = builder.getVarFromNode(this, this.name, builder.getVectorType(this.getNodeType(builder)));
		var propertyName = builder.getPropertyName(nodeVar);
		var snippet = this.node.build(builder, nodeVar.type);
		builder.addLineFlowCode(propertyName + " = " + snippet);
		return propertyName;
	}

}

static function temp(node:Node, name:String = null):VarNode {
	return new VarNode(node, name);
}

static function toVar(...params):VarNode {
	return temp(...params).append();
}

ShaderNode.addNodeElement('temp', temp);
ShaderNode.addNodeElement('toVar', toVar);
ShaderNode.addNodeClass('VarNode', VarNode);