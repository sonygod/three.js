import LightingNode from "./LightingNode";
import Node from "../core/Node";

class IrradianceNode extends LightingNode {

	public var node: Node;

	public function new(node: Node) {
		super();
		this.node = node;
	}

	override public function setup(builder: Dynamic) {
		builder.context.irradiance.addAssign(this.node);
	}
}

Node.addNodeClass("IrradianceNode", IrradianceNode);