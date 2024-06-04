import node.Node;
import node.ShaderNode;
import three.WebGLCoordinateSystem;
import three.BackSide;

class FrontFacingNode extends Node {

	public var isFrontFacingNode:Bool = true;

	public function new() {
		super('bool');
	}

	override function generate(builder:ShaderNode):String {
		if (builder.renderer.coordinateSystem == WebGLCoordinateSystem) {
			if (builder.material.side == BackSide) {
				return 'false';
			}
		}
		return builder.getFrontFacing();
	}

}

var frontFacing = ShaderNode.nodeImmutable(FrontFacingNode);
var faceDirection = ShaderNode.float(frontFacing).mul(2.0).sub(1.0);

Node.addNodeClass('FrontFacingNode', FrontFacingNode);