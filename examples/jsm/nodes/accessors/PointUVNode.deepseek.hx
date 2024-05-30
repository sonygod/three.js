import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class PointUVNode extends Node {

	public function new() {

		super( 'vec2' );

		this.isPointUVNode = true;

	}

	public function generate( /*builder*/ ) {

		return 'vec2( gl_PointCoord.x, 1.0 - gl_PointCoord.y )';

	}

}

static public var pointUV = ShaderNode.nodeImmutable( PointUVNode );

Node.addNodeClass( 'PointUVNode', PointUVNode );