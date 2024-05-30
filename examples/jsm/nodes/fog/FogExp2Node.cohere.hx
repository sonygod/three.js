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

@:extern
static public var FogExp2Node_static : FogExp2Node_static;

typedef FogExp2Node_static = {
	public function new(colorNode:Dynamic, densityNode:Dynamic):FogExp2Node;
}

@:export default
static public var densityFog = nodeProxy(FogExp2Node);

addNodeElement('densityFog', densityFog);
addNodeClass('FogExp2Node', FogExp2Node);