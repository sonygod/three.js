import FogNode from './FogNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class FogExp2Node extends FogNode {

	public var isFogExp2Node:Bool = true;
	public var densityNode:Dynamic;

	public function new(colorNode:Dynamic, densityNode:Dynamic) {
		super(colorNode);
		this.densityNode = densityNode;
	}

	public function setup(builder:Dynamic):Dynamic {
		var viewZ = this.getViewZNode(builder);
		var density = this.densityNode;

		return density.mul(density, viewZ, viewZ).negate().exp().oneMinus();
	}

}

export default FogExp2Node;

export var densityFog = nodeProxy(FogExp2Node);

addNodeElement('densityFog', densityFog);

addNodeClass('FogExp2Node', FogExp2Node);