import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class ExpressionNode extends Node {

	public function new(snippet:String = '', nodeType:String = 'void') {
		super(nodeType);
		this.snippet = snippet;
	}

	public function generate(builder:ShaderNode, output:Dynamic) {
		var type = this.getNodeType(builder);
		var snippet = this.snippet;

		if (type == 'void') {
			builder.addLineFlowCode(snippet);
		} else {
			return builder.format(`( ${snippet} )`, type, output);
		}
	}

	public var snippet:String;
}

static function expression(snippet:String, nodeType:String = 'void'):ExpressionNode {
	return new ExpressionNode(snippet, nodeType);
}

Node.addNodeClass('ExpressionNode', ExpressionNode);