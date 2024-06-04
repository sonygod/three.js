import TempNode from "../core/TempNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class RotateUVNode extends TempNode {

	public var uvNode:Node;
	public var rotationNode:Node;
	public var centerNode:Node;

	public function new(uvNode:Node, rotationNode:Node, centerNode:Node = ShaderNode.vec2(0.5)) {
		super("vec2");
		this.uvNode = uvNode;
		this.rotationNode = rotationNode;
		this.centerNode = centerNode;
	}

	override public function setup():Node {
		var vector = uvNode.sub(centerNode);
		return vector.rotate(rotationNode).add(centerNode);
	}
}

class RotateUV extends Node {
	public static function create(uvNode:Node, rotationNode:Node, centerNode:Node = ShaderNode.vec2(0.5)):RotateUV {
		return new RotateUV(new RotateUVNode(uvNode, rotationNode, centerNode));
	}
}

ShaderNode.addNodeElement("rotateUV", RotateUV);
Node.addNodeClass("RotateUVNode", RotateUVNode);

export { RotateUV, RotateUVNode };