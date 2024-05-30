import TempNode from '../core/TempNode';
import { addNodeClass } from '../core/Node';
import { addNodeElement, nodeProxy, vec2 } from '../shadernode/ShaderNode';

class RotateUVNode extends TempNode {

	public var uvNode:Dynamic;
	public var rotationNode:Dynamic;
	public var centerNode:Dynamic;

	public function new(uvNode:Dynamic, rotationNode:Dynamic, centerNode:Dynamic = vec2(0.5)) {
		super('vec2');

		this.uvNode = uvNode;
		this.rotationNode = rotationNode;
		this.centerNode = centerNode;
	}

	public function setup():Dynamic {
		var vector = this.uvNode.sub(this.centerNode);

		return vector.rotate(this.rotationNode).add(this.centerNode);
	}

}

export default RotateUVNode;

export var rotateUV = nodeProxy(RotateUVNode);

addNodeElement('rotateUV', rotateUV);

addNodeClass('RotateUVNode', RotateUVNode);