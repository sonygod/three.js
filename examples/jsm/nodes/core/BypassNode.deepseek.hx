import Node;
import ShaderNode;

class BypassNode extends Node {

	public function new(returnNode:Node, callNode:Node) {
		super();

		this.isBypassNode = true;

		this.outputNode = returnNode;
		this.callNode = callNode;
	}

	public function getNodeType(builder:ShaderNode.Builder):String {
		return this.outputNode.getNodeType(builder);
	}

	public function generate(builder:ShaderNode.Builder):String {
		var snippet = this.callNode.build(builder, 'void');

		if (snippet != '') {
			builder.addLineFlowCode(snippet);
		}

		return this.outputNode.build(builder);
	}

}

static function bypass(returnNode:Node, callNode:Node):BypassNode {
	return new BypassNode(returnNode, callNode);
}

ShaderNode.addNodeElement('bypass', bypass);

Node.addNodeClass('BypassNode', BypassNode);