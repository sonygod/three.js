import Node, { addNodeClass } from '../core/Node.js';
import { nodeProxy } from '../shadernode/ShaderNode.js';

class ExpressionNode extends Node {

	public var snippet:String;

	public function new(snippet:String = "", nodeType:String = "void") {

		super(nodeType);

		this.snippet = snippet;

	}

	public function generate(builder:Dynamic, output:Dynamic):Dynamic {

		var type:String = this.getNodeType(builder);
		var snippet:String = this.snippet;

		if (type == 'void') {

			builder.addLineFlowCode(snippet);

		} else {

			return builder.format("( ${ snippet } )", type, output);

		}

	}

}

export default ExpressionNode;

export const expression:Dynamic = nodeProxy(ExpressionNode);

addNodeClass('ExpressionNode', ExpressionNode);