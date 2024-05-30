import TempNode from '../core/TempNode.hx';
import { transformedNormalView } from '../accessors/NormalNode.hx';
import { positionViewDirection } from '../accessors/PositionNode.hx';
import { nodeImmutable, vec2, vec3 } from '../shadernode/ShaderNode.hx';
import { addNodeClass } from '../core/Node.hx';

class MatcapUVNode extends TempNode {
	public function new() {
		super('vec2');
	}

	public function setup() : Vec2 {
		var x = vec3(positionViewDirection.z, 0, -positionViewDirection.x).normalize();
		var y = positionViewDirection.cross(x);

		return vec2(x.dot(transformedNormalView), y.dot(transformedNormalView)).mul(0.495).add(0.5); // 0.495 to remove artifacts caused by undersized matcap disks
	}

}

static function matcapUV() : MatcapUVNode {
	return nodeImmutable(MatcapUVNode);
}

addNodeClass('MatcapUVNode', MatcapUVNode);

export { matcapUV, MatcapUVNode };