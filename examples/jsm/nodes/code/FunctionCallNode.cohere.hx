import TempNode from '../core/TempNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeArray, nodeObject, nodeObjects } from '../shadernode/ShaderNode.hx';

class FunctionCallNode extends TempNode {

	public functionNode: FunctionNode;
	public parameters: { [ name : String ] : Node } | Array<Node>;

	public function new(functionNode: FunctionNode = null, parameters: { [ name : String ] : Node } | Array<Node> = {}) {
		super();
		this.functionNode = functionNode;
		this.parameters = parameters;
	}

	public function setParameters(parameters: { [ name : String ] : Node } | Array<Node>) : FunctionCallNode {
		this.parameters = parameters;
		return this;
	}

	public function getParameters() : { [ name : String ] : Node } | Array<Node> {
		return this.parameters;
	}

	override function getNodeType(builder: ShaderBuilder) : NodeType {
		return this.functionNode.getNodeType(builder);
	}

	override function generate(builder: ShaderBuilder) : String {
		var params: Array<String> = [];
		var functionNode: FunctionNode = this.functionNode;
		var inputs: Array<Node> = functionNode.getInputs(builder);
		var parameters: { [ name : String ] : Node } | Array<Node> = this.parameters;

		if (Type.isArray(parameters)) {
			for (i in 0...parameters.length) {
				var inputNode: Node = inputs[i];
				var node: Node = parameters[i];
				params.push(node.build(builder, inputNode.getType()));
			}
		} else {
			for (inputNode in inputs) {
				var node: Node = parameters[inputNode.getName()];
				if (node != null) {
					params.push(node.build(builder, inputNode.getType()));
				} else {
					throw haxe.Exception.thrown("FunctionCallNode: Input '" + inputNode.getName() + "' not found in FunctionNode.");
				}
			}
		}

		var functionName: String = functionNode.build(builder, 'property');

		return functionName + '(' + params.join(', ') + ')';
	}

}

static function call(func: FunctionNode, ...params: Array<Node>) : Node {
	if (params.length > 1 || (params.length == 1 && params[0] != null && params[0].isNode)) {
		params = nodeArray(params);
	} else {
		params = nodeObjects(params[0]);
	}

	return nodeObject(new FunctionCallNode(nodeObject(func), params));
}

static function __init__() {
	addNodeElement('call', call);
	addNodeClass('FunctionCallNode', FunctionCallNode);
}