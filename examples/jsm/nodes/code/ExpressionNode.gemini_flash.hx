import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class ExpressionNode extends Node {

	public var snippet:String;

	public function new(snippet:String = "", nodeType:String = "void") {
		super(nodeType);
		this.snippet = snippet;
	}

	override public function generate(builder:ShaderNode, output:String):Dynamic {
		var type = this.getNodeType(builder);
		var snippet = this.snippet;

		if (type == "void") {
			builder.addLineFlowCode(snippet);
		} else {
			return builder.format("( " + snippet + " )", type, output);
		}
	}
}

class ExpressionNodeProxy extends ShaderNode {
	public function new(snippet:String, nodeType:String = "void") {
		super(new ExpressionNode(snippet, nodeType));
	}
}

var expression = new ExpressionNodeProxy;
Node.addNodeClass("ExpressionNode", ExpressionNode);