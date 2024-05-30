import Node from '../core/Node.hx';
import { Float, addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class RemapNode extends Node {
	public var node:Node;
	public var inLowNode:Node;
	public var inHighNode:Node;
	public var outLowNode:Float;
	public var outHighNode:Float;
	public var doClamp:Bool;

	public function new(node:Node, inLowNode:Node, inHighNode:Node, outLowNode:Float = Float.create(0), outHighNode:Float = Float.create(1)) {
		super();
		this.node = node;
		this.inLowNode = inLowNode;
		this.inHighNode = inHighNode;
		this.outLowNode = outLowNode;
		this.outHighNode = outHighNode;
		this.doClamp = true;
	}

	public function setup():Float {
		var t = node.sub(inLowNode).div(inHighNode.sub(inLowNode));
		if (doClamp) t = t.clamp();
		return t.mul(outHighNode.sub(outLowNode)).add(outLowNode);
	}
}

class RemapNode_Statics {
	public static inline var __properties__ = {
		'default' : 'remap',
		'remapClamp' : 'remapClamp'
	}
}

static extension RemapNode_Extensions {
	public static function remap(node:Node, inLowNode:Node, inHighNode:Node, outLowNode:Float = Float.create(0), outHighNode:Float = Float.create(1), ?doClamp:Bool) {
		return new RemapNode(node, inLowNode, inHighNode, outLowNode, outHighNode, doClamp);
	}

	public static function remapClamp(node:Node, inLowNode:Node, inHighNode:Node, outLowNode:Float = Float.create(0), outHighNode:Float = Float.create(1)) {
		return new RemapNode(node, inLowNode, inHighNode, outLowNode, outHighNode, true);
	}
}

addNodeElement('remap', RemapNode.remap);
addNodeElement('remapClamp', RemapNode.remapClamp);

addNodeClass('RemapNode', RemapNode);