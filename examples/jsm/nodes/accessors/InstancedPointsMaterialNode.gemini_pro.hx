import MaterialNode from "./MaterialNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class InstancedPointsMaterialNode extends MaterialNode {

	public static POINT_WIDTH:String = "pointWidth";

	public setup( /*builder*/ ):Float {

		return this.getFloat(this.scope);

	}

}

var materialPointWidth = ShaderNode.nodeImmutable(InstancedPointsMaterialNode, InstancedPointsMaterialNode.POINT_WIDTH);

Node.addNodeClass("InstancedPointsMaterialNode", InstancedPointsMaterialNode);

export { InstancedPointsMaterialNode, materialPointWidth };