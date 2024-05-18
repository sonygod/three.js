package three.js.examples.jm.nodes.accessors;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class PointUVNode extends Node {

	public var isPointUVNode:Bool;

	public function new() {
		super("vec2");
		this.isPointUVNode = true;
	}

	override public function generate(builder:Dynamic):String {
		return 'vec2( gl_PointCoord.x, 1.0 - gl_PointCoord.y )';
	}

}

class PointUVNodeFactory {
	public static var pointUV(get, never):PointUVNode;
	private static function get_pointUV():PointUVNode {
		return nodeImmutable(new PointUVNode());
	}
}

Node.addNodeClass("PointUVNode", PointUVNode);