import FogNode from "./FogNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class FogExp2Node extends FogNode {

	public var densityNode:ShaderNode;

	public function new(colorNode:ShaderNode, densityNode:ShaderNode) {
		super(colorNode);
		this.isFogExp2Node = true;
		this.densityNode = densityNode;
	}

	public function setup(builder:ShaderNode.Builder):ShaderNode {
		var viewZ = this.getViewZNode(builder);
		var density = this.densityNode;
		return density.mul(density, viewZ, viewZ).negate().exp().oneMinus();
	}

}

var densityFog:ShaderNode.Proxy = ShaderNode.nodeProxy(FogExp2Node);

ShaderNode.addNodeElement("densityFog", densityFog);

Node.addNodeClass("FogExp2Node", FogExp2Node);