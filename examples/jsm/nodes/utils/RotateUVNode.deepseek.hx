import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class RotateUVNode extends TempNode {

	public function new(uvNode:ShaderNode, rotationNode:ShaderNode, centerNode:ShaderNode = vec2(0.5)) {
		super('vec2');

		this.uvNode = uvNode;
		this.rotationNode = rotationNode;
		this.centerNode = centerNode;
	}

	public function setup():ShaderNode {
		var vector:ShaderNode = this.uvNode.sub(this.centerNode);
		return vector.rotate(this.rotationNode).add(this.centerNode);
	}

}

static function rotateUV(uvNode:ShaderNode, rotationNode:ShaderNode, centerNode:ShaderNode = vec2(0.5)):ShaderNode {
	return new RotateUVNode(uvNode, rotationNode, centerNode);
}

Node.addNodeElement('rotateUV', rotateUV);

Node.addNodeClass('RotateUVNode', RotateUVNode);