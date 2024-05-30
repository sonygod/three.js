import Node from './Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class VarNode extends Node {
	public var node: Node;
	public var name: String;
	public isVarNode: Bool = true;

	public function new(node: Node, name: String = null) {
		super();
		this.node = node;
		this.name = name;
	}

	public function isGlobal(): Bool {
		return true;
	}

	public function getHash(builder: Dynamic): Int {
		return this.name ? this.name.hashCode() : super.getHash(builder);
	}

	public function getNodeType(builder: Dynamic): Int {
		return this.node.getNodeType(builder);
	}

	public function generate(builder: Dynamic): String {
		var nodeVar = builder.getVarFromNode(this, this.name, builder.getVectorType(this.getNodeType(builder)));
		var propertyName = builder.getPropertyName(nodeVar);
		var snippet = this.node.build(builder, nodeVar.type);
		builder.addLineFlowCode(propertyName + ' = ' + snippet);
		return propertyName;
	}
}

@:export("default")
class VarNode_
{
	public static inline var temp = nodeProxy(VarNode);
}

addNodeElement('temp', VarNode_.temp); // @TODO: Will be removed in the future
addNodeElement('toVar', function(...params) { return VarNode_.temp(...params).append(); });
addNodeClass('VarNode', VarNode);