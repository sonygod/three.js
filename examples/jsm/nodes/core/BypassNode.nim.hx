import Node, { addNodeClass } from './Node.js';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';

class BypassNode extends Node {

	public var isBypassNode:Bool = true;
	public var outputNode:Node;
	public var callNode:Node;

	public function new(returnNode:Node, callNode:Node) {
		super();
		this.outputNode = returnNode;
		this.callNode = callNode;
	}

	public function getNodeType(builder:Dynamic):Dynamic {
		return this.outputNode.getNodeType(builder);
	}

	public function generate(builder:Dynamic):Dynamic {
		var snippet = this.callNode.build(builder, 'void');
		if (snippet != '') {
			builder.addLineFlowCode(snippet);
		}
		return this.outputNode.build(builder);
	}

}

export default BypassNode;

export var bypass = nodeProxy(BypassNode);

addNodeElement('bypass', bypass);

addNodeClass('BypassNode', BypassNode);