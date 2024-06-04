import LightingNode from "./LightingNode";
import Node from "../core/Node";

class AONode extends LightingNode {

	public var aoNode: Node;

	public function new(aoNode: Node = null) {
		super();
		this.aoNode = aoNode;
	}

	override public function setup(builder: Node): Void {
		var aoIntensity = 1;
		var aoNode = this.aoNode.x.sub(1.0).mul(aoIntensity).add(1.0);

		builder.context.ambientOcclusion.mulAssign(aoNode);
	}
}

Node.addNodeClass('AONode', AONode);

export default AONode;