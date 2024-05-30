import Node, { addNodeClass } from '../core/Node.js';
import { nodeImmutable } from '../shadernode/ShaderNode.js';

class PointUVNode extends Node {

	public function new() {

		super('vec2');

		this.isPointUVNode = true;

	}

	public function generate( /*builder*/ ) {

		return 'vec2( gl_PointCoord.x, 1.0 - gl_PointCoord.y )';

	}

}

export default PointUVNode;

export const pointUV = nodeImmutable(PointUVNode);

addNodeClass('PointUVNode', PointUVNode);