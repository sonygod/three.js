import three.jsm.nodes.core.TempNode;
import three.jsm.nodes.core.Node;
import three.jsm.nodes.shadernode.ShaderNode;

class FunctionCallNode extends TempNode {

	public var functionNode: ShaderNode;
	public var parameters: Dynamic;

	public function new(functionNode: ShaderNode = null, parameters: Dynamic = {}) {

		super();

		this.functionNode = functionNode;
		this.parameters = parameters;

	}

	public function setParameters(parameters: Dynamic): FunctionCallNode {

		this.parameters = parameters;

		return this;

	}

	public function getParameters(): Dynamic {

		return this.parameters;

	}

	public function getNodeType(builder: Dynamic): Dynamic {

		return this.functionNode.getNodeType(builder);

	}

	public function generate(builder: Dynamic): String {

		var params: Array<String> = [];

		var functionNode: ShaderNode = this.functionNode;

		var inputs: Array<Dynamic> = functionNode.getInputs(builder);
		var parameters: Dynamic = this.parameters;

		if (Std.is(parameters, Array)) {

			for (i in 0...parameters.length) {

				var inputNode: Dynamic = inputs[i];
				var node: ShaderNode = parameters[i];

				params.push(node.build(builder, inputNode.type));

			}

		} else {

			for (inputNode in inputs) {

				var node: ShaderNode = Reflect.field(parameters, inputNode.name);

				if (node !== null) {

					params.push(node.build(builder, inputNode.type));

				} else {

					throw new Error("FunctionCallNode: Input '" + inputNode.name + "' not found in FunctionNode.");

				}

			}

		}

		var functionName: String = functionNode.build(builder, "property");

		return functionName + "( " + params.join(", ") + " )";

	}

}

var call = function(func: ShaderNode, params: Dynamic ...): ShaderNode {

	params = params.length > 1 || (params[0] && Std.is(params[0], ShaderNode)) ? ShaderNode.nodeArray(params) : ShaderNode.nodeObjects(params[0]);

	return ShaderNode.nodeObject(new FunctionCallNode(func, params));

};

ShaderNode.addNodeElement("call", call);

Node.addNodeClass("FunctionCallNode", FunctionCallNode);