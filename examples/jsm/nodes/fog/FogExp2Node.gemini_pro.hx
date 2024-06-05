import FogNode from "./FogNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class FogExp2Node extends FogNode {

	public var isFogExp2Node:Bool = true;

	public var densityNode:ShaderNode;

	public function new(colorNode:ShaderNode, densityNode:ShaderNode) {
		super(colorNode);
		this.densityNode = densityNode;
	}

	public function setup(builder:ShaderNode):ShaderNode {
		var viewZ = this.getViewZNode(builder);
		var density = this.densityNode;
		return density.mul(density, viewZ, viewZ).negate().exp().oneMinus();
	}

}

var densityFog = ShaderNode.nodeProxy(FogExp2Node);

Node.addNodeElement("densityFog", densityFog);

Node.addNodeClass("FogExp2Node", FogExp2Node);