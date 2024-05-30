import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class RemapNode extends Node {

	public function new(node:ShaderNode, inLowNode:ShaderNode, inHighNode:ShaderNode, outLowNode:Float = 0, outHighNode:Float = 1) {
		super();

		this.node = node;
		this.inLowNode = inLowNode;
		this.inHighNode = inHighNode;
		this.outLowNode = outLowNode;
		this.outHighNode = outHighNode;

		this.doClamp = true;
	}

	public function setup():ShaderNode {
		var t:ShaderNode = this.node.sub(this.inLowNode).div(this.inHighNode.sub(this.inLowNode));

		if (this.doClamp) t = t.clamp();

		return t.mul(this.outHighNode - this.outLowNode).add(this.outLowNode);
	}

	public var node:ShaderNode;
	public var inLowNode:ShaderNode;
	public var inHighNode:ShaderNode;
	public var outLowNode:Float;
	public var outHighNode:Float;
	public var doClamp:Bool;
}

static function remap(node:ShaderNode, inLowNode:ShaderNode, inHighNode:ShaderNode, outLowNode:Float = 0, outHighNode:Float = 1, doClamp:Bool = false):ShaderNode {
	return new RemapNode(node, inLowNode, inHighNode, outLowNode, outHighNode).setup();
}

static function remapClamp(node:ShaderNode, inLowNode:ShaderNode, inHighNode:ShaderNode, outLowNode:Float = 0, outHighNode:Float = 1):ShaderNode {
	return new RemapNode(node, inLowNode, inHighNode, outLowNode, outHighNode).setup();
}

Node.addNodeElement('remap', remap);
Node.addNodeElement('remapClamp', remapClamp);

Node.addNodeClass('RemapNode', RemapNode);