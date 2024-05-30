import three.Node;
import three.shadernode.ShaderNode;
import three.BackSide;
import three.WebGLCoordinateSystem;

class FrontFacingNode extends Node {

	public function new() {

		super('bool');

		this.isFrontFacingNode = true;

	}

	public function generate(builder:ShaderNode.Builder):String {

		var renderer = builder.renderer;
		var material = builder.material;

		if (renderer.coordinateSystem == WebGLCoordinateSystem) {

			if (material.side == BackSide) {

				return 'false';

			}

		}

		return builder.getFrontFacing();

	}

}

static var frontFacing = ShaderNode.nodeImmutable(FrontFacingNode);
static var faceDirection = ShaderNode.float(frontFacing).mul(2.0).sub(1.0);

Node.addNodeClass('FrontFacingNode', FrontFacingNode);