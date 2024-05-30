import Node, { addNodeClass } from './Node.js';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';

class VarNode extends Node {

	var node:Node;
	var name:String;

	var isVarNode:Bool = true;

	public function new(node:Node, name:String = null) {
		super();

		this.node = node;
		this.name = name;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function getHash(builder:Dynamic):String {
		return this.name != null ? this.name : super.getHash(builder);
	}

	public function getNodeType(builder:Dynamic):String {
		return this.node.getNodeType(builder);
	}

	public function generate(builder:Dynamic):String {
		var nodeVar = builder.getVarFromNode(this, this.name, builder.getVectorType(this.getNodeType(builder)));

		var propertyName = builder.getPropertyName(nodeVar);

		var snippet = node.build(builder, nodeVar.type);

		builder.addLineFlowCode("${propertyName} = ${snippet}");

		return propertyName;
	}
}

export default VarNode;

var temp = nodeProxy(VarNode);

addNodeElement('temp', temp); // @TODO: Will be removed in the future
addNodeElement('toVar', function(...params) return temp(...params).append(); );

addNodeClass('VarNode', VarNode);