import TempNode from "../core/TempNode";
import NormalNode from "../accessors/NormalNode";
import PositionNode from "../accessors/PositionNode";
import {nodeImmutable, vec2, vec3} from "../shadernode/ShaderNode";
import Node from "../core/Node";

class MatcapUVNode extends TempNode {

	public function new() {
		super("vec2");
	}

	override public function setup() : ShaderNode {
		var x = vec3(PositionNode.positionViewDirection.z, 0, -PositionNode.positionViewDirection.x).normalize();
		var y = PositionNode.positionViewDirection.cross(x);
		return vec2(x.dot(NormalNode.transformedNormalView), y.dot(NormalNode.transformedNormalView)).mul(0.495).add(0.5); // 0.495 to remove artifacts caused by undersized matcap disks
	}

}

export var matcapUV = nodeImmutable(MatcapUVNode);

Node.addNodeClass("MatcapUVNode", MatcapUVNode);