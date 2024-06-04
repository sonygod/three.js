import TempNode from "../core/TempNode";
import {addNodeClass, addNodeElement, nodeArray, nodeObject, nodeObjects} from "../shadernode/ShaderNode";

class FunctionCallNode extends TempNode {

	public functionNode:Dynamic;
	public parameters:Dynamic;

	public function new(functionNode:Dynamic = null, parameters:Dynamic = {}) {
		super();
		this.functionNode = functionNode;
		this.parameters = parameters;
	}

	public function setParameters(parameters:Dynamic):FunctionCallNode {
		this.parameters = parameters;
		return this;
	}

	public function getParameters():Dynamic {
		return this.parameters;
	}

	public function getNodeType(builder:Dynamic):Dynamic {
		return this.functionNode.getNodeType(builder);
	}

	public function generate(builder:Dynamic):String {
		var params:Array<String> = [];
		var functionNode = this.functionNode;
		var inputs = functionNode.getInputs(builder);
		var parameters = this.parameters;

		if (Std.isOfType(parameters, Array)) {
			for (i in 0...parameters.length) {
				var inputNode = inputs[i];
				var node = parameters[i];
				params.push(node.build(builder, inputNode.type));
			}
		} else {
			for (inputNode in inputs) {
				var node = parameters[inputNode.name];
				if (node != null) {
					params.push(node.build(builder, inputNode.type));
				} else {
					throw "FunctionCallNode: Input '${inputNode.name}' not found in FunctionNode.";
				}
			}
		}

		var functionName = functionNode.build(builder, 'property');

		return "${functionName}(${params.join(', ')})";
	}
}

export function call(func:Dynamic, ...params:Dynamic):Dynamic {
	params = params.length > 1 || (params[0] != null && Std.isOfType(params[0], {isNode:Bool})) ? nodeArray(params) : nodeObjects(params[0]);
	return nodeObject(new FunctionCallNode(nodeObject(func), params));
}

addNodeElement('call', call);
addNodeClass('FunctionCallNode', FunctionCallNode);