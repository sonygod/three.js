import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class FunctionCallNode extends TempNode {

	public function functionNode(functionNode:Null<FunctionNode> = null, parameters:{} = {}) {
		super();
		this.functionNode = functionNode;
		this.parameters = parameters;
	}

	public function setParameters(parameters:{}):FunctionCallNode {
		this.parameters = parameters;
		return this;
	}

	public function getParameters():{} {
		return this.parameters;
	}

	public function getNodeType(builder:ShaderNodeBuilder):String {
		return this.functionNode.getNodeType(builder);
	}

	public function generate(builder:ShaderNodeBuilder):String {
		var params = [];
		var functionNode = this.functionNode;
		var inputs = functionNode.getInputs(builder);
		var parameters = this.parameters;

		if (Std.is(parameters, Array)) {
			for (i in Std.range(parameters.length)) {
				var inputNode = inputs[i];
				var node = parameters[i];
				params.push(node.build(builder, inputNode.type));
			}
		} else {
			for (inputNode in inputs) {
				var node = parameters[inputNode.name];
				if (node !== undefined) {
					params.push(node.build(builder, inputNode.type));
				} else {
					throw 'FunctionCallNode: Input \'${inputNode.name}\' not found in FunctionNode.';
				}
			}
		}

		var functionName = functionNode.build(builder, 'property');
		return '${functionName}( ${params.join(', ')} )';
	}

}

static function call(func:Null<FunctionNode>, params:Array<Dynamic>):FunctionCallNode {
	params = params.length > 1 || (params.length == 1 && params[0].isNode == true) ? ShaderNode.nodeArray(params) : ShaderNode.nodeObjects(params[0]);
	return ShaderNode.nodeObject(new FunctionCallNode(ShaderNode.nodeObject(func), params));
}

Node.addNodeElement('call', call);
Node.addNodeClass('FunctionCallNode', FunctionCallNode);