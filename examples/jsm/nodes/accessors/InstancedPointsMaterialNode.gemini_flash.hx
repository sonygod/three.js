import MaterialNode from "./MaterialNode";
import haxe.ds.StringMap;
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class InstancedPointsMaterialNode extends MaterialNode {

	public static var POINT_WIDTH:String = "pointWidth";

	public function new() {
		super();
	}

	override function setup(builder:Dynamic):Dynamic {
		return this.getFloat(this.scope);
	}

}

var materialPointWidth:Dynamic = ShaderNode.nodeImmutable(InstancedPointsMaterialNode, InstancedPointsMaterialNode.POINT_WIDTH);

Node.addNodeClass("InstancedPointsMaterialNode", InstancedPointsMaterialNode);

export { InstancedPointsMaterialNode, materialPointWidth };