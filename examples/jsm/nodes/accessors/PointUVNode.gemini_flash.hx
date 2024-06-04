import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class PointUVNode extends Node {

	public var isPointUVNode:Bool = true;

	public function new() {
		super("vec2");
	}

	override public function generate(builder:Dynamic):String {
		return "vec2( gl_PointCoord.x, 1.0 - gl_PointCoord.y )";
	}
}

class PointUVNodeImmutable extends ShaderNode {

	public function new() {
		super(PointUVNode);
	}

}

var pointUV = new PointUVNodeImmutable();
Node.addNodeClass("PointUVNode", PointUVNode);