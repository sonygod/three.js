import Node from './Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class BypassNode extends Node {
	public isBypassNode:Bool;
	public outputNode:Dynamic;
	public callNode:Dynamic;

	public function new(returnNode:Dynamic, callNode:Dynamic) {
		super();
		this.isBypassNode = true;
		this.outputNode = returnNode;
		this.callNode = callNode;
	}

	public function getNodeType(builder:Dynamic):Dynamic {
		return this.outputNode.getNodeType(builder);
	}

	public function generate(builder:Dynamic):Dynamic {
		var snippet = this.callNode.build(builder, 'Void');
		if (snippet != '') {
			builder.addLineFlowCode(snippet);
		}
		return this.outputNode.build(builder);
	}
}

@:reflect.virtual
class BypassNode_virtual {
	public static inline function __bypassNode_virtual_bypass(returnNode:Dynamic, callNode:Dynamic):BypassNode {
		return new BypassNode(returnNode, callNode);
	}
}

var BypassNode_tmp = BypassNode_virtual.__bypassNode_virtual_bypass;

var bypass = nodeProxy(BypassNode_tmp);

addNodeElement('bypass', bypass);

addNodeClass('BypassNode', BypassNode);

class Void {
}