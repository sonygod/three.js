import TempNode from '../core/TempNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy, vec2 } from '../shadernode/ShaderNode.hx';

class RotateUVNode extends TempNode {

	public function new(uvNode:Node, rotationNode:Node, centerNode:Node = vec2(0.5)) {
		super('vec2');
		this.uvNode = uvNode;
		this.rotationNode = rotationNode;
		this.centerNode = centerNode;
	}

	public function setup():Node {
		var vector = uvNode.sub(centerNode);
		return vector.rotate(rotationNode).add(centerNode);
	}

}

static function __<T:Node>():RotateUVNode {
	return RotateUVNode_hx_0;
}

static var RotateUVNode_hx_0:RotateUVNode = new RotateUVNode(null, null, null);

@:autoBuild
static public function rotateUV(uvNode:Node, rotationNode:Node, centerNode:Node = vec2(0.5)):Node {
	return RotateUVNode_hx_0.set(uvNode, rotationNode, centerNode);
}

static function __init__() {
	addNodeElement('rotateUV', rotateUV);
	addNodeClass('RotateUVNode', RotateUVNode);
}