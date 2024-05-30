import three.examples.jsm.nodes.core.TempNode;
import three.examples.jsm.nodes.core.Node;
import three.examples.jsm.nodes.shadernode.ShaderNode;
import three.examples.jsm.nodes.math.MathNode;

class RotateNode extends TempNode {

	var positionNode:ShaderNode;
	var rotationNode:ShaderNode;

	public function new(positionNode:ShaderNode, rotationNode:ShaderNode) {
		super();
		this.positionNode = positionNode;
		this.rotationNode = rotationNode;
	}

	public function getNodeType(builder:ShaderNode):String {
		return this.positionNode.getNodeType(builder);
	}

	public function setup(builder:ShaderNode):ShaderNode {
		var nodeType = this.getNodeType(builder);

		if (nodeType == 'vec2') {
			var cosAngle = rotationNode.cos();
			var sinAngle = rotationNode.sin();

			var rotationMatrix = ShaderNode.mat2(
				cosAngle, sinAngle,
				sinAngle.negate(), cosAngle
			);

			return rotationMatrix.mul(positionNode);

		} else {
			var rotation = rotationNode;
			var rotationXMatrix = ShaderNode.mat4(ShaderNode.vec4(1.0, 0.0, 0.0, 0.0), ShaderNode.vec4(0.0, MathNode.cos(rotation.x), MathNode.sin(rotation.x).negate(), 0.0), ShaderNode.vec4(0.0, MathNode.sin(rotation.x), MathNode.cos(rotation.x), 0.0), ShaderNode.vec4(0.0, 0.0, 0.0, 1.0));
			var rotationYMatrix = ShaderNode.mat4(ShaderNode.vec4(MathNode.cos(rotation.y), 0.0, MathNode.sin(rotation.y), 0.0), ShaderNode.vec4(0.0, 1.0, 0.0, 0.0), ShaderNode.vec4(MathNode.sin(rotation.y).negate(), 0.0, MathNode.cos(rotation.y), 0.0), ShaderNode.vec4(0.0, 0.0, 0.0, 1.0));
			var rotationZMatrix = ShaderNode.mat4(ShaderNode.vec4(MathNode.cos(rotation.z), MathNode.sin(rotation.z).negate(), 0.0, 0.0), ShaderNode.vec4(MathNode.sin(rotation.z), MathNode.cos(rotation.z), 0.0, 0.0), ShaderNode.vec4(0.0, 0.0, 1.0, 0.0), ShaderNode.vec4(0.0, 0.0, 0.0, 1.0));

			return rotationXMatrix.mul(rotationYMatrix).mul(rotationZMatrix).mul(ShaderNode.vec4(positionNode, 1.0)).xyz;
		}
	}
}

static function rotate(positionNode:ShaderNode, rotationNode:ShaderNode):ShaderNode {
	return new RotateNode(positionNode, rotationNode);
}

Node.addNodeElement('rotate', rotate);

Node.addNodeClass('RotateNode', RotateNode);