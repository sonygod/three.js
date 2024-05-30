import FogNode from './FogNode.js';
import { smoothstep } from '../math/MathNode.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';

class FogRangeNode extends FogNode {

	public var isFogRangeNode:Bool = true;
	public var nearNode:Dynamic;
	public var farNode:Dynamic;

	public function new(colorNode:Dynamic, nearNode:Dynamic, farNode:Dynamic) {
		super(colorNode);

		this.nearNode = nearNode;
		this.farNode = farNode;
	}

	public function setup(builder:Dynamic):Dynamic {
		const viewZ:Dynamic = this.getViewZNode(builder);

		return smoothstep(this.nearNode, this.farNode, viewZ);
	}
}

export default FogRangeNode;

export const rangeFog = nodeProxy(FogRangeNode);

addNodeElement('rangeFog', rangeFog);

addNodeClass('FogRangeNode', FogRangeNode);