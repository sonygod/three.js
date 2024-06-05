import Node from "../core/Node";
import PositionNode from "../accessors/PositionNode";
import ShaderNode from "../shadernode/ShaderNode";

class FogNode extends Node {

	public var isFogNode:Bool = true;

	public var colorNode:Node;
	public var factorNode:Node;

	public function new(colorNode:Node, factorNode:Node) {
		super("float");
		this.colorNode = colorNode;
		this.factorNode = factorNode;
	}

	public function getViewZNode(builder:ShaderNode.Builder):Node {
		var viewZ:Node = builder.context.getViewZ(this);
		if (viewZ != null) {
			return viewZ;
		}
		return PositionNode.positionView.z.negate();
	}

	public function setup():Node {
		return this.factorNode;
	}

}

class FogNodeProxy extends ShaderNode.NodeProxy {
	public function new() {
		super(FogNode);
	}
}

var fog:FogNodeProxy = new FogNodeProxy();

ShaderNode.addNodeElement("fog", fog);
ShaderNode.addNodeClass("FogNode", FogNode);