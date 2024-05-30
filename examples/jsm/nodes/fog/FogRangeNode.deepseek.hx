import FogNode from './FogNode.hx';
import MathNode from '../math/MathNode.hx';
import Node from '../core/Node.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';

class FogRangeNode extends FogNode {

	public function new(colorNode:Dynamic, nearNode:Dynamic, farNode:Dynamic) {
		super(colorNode);

		this.isFogRangeNode = true;

		this.nearNode = nearNode;
		this.farNode = farNode;
	}

	public function setup(builder:Dynamic):Dynamic {
		var viewZ = this.getViewZNode(builder);

		return MathNode.smoothstep(this.nearNode, this.farNode, viewZ);
	}

}

static var rangeFog = ShaderNode.nodeProxy(FogRangeNode);

ShaderNode.addNodeElement('rangeFog', rangeFog);

Node.addNodeClass('FogRangeNode', FogRangeNode);