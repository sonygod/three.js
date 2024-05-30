import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.accessors.NormalNode;
import three.js.examples.jsm.nodes.accessors.PositionNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.core.Node;

class MatcapUVNode extends TempNode {

	public function new() {
		super('vec2');
	}

	public function setup() {
		var x = vec3(PositionNode.positionViewDirection.z, 0, PositionNode.positionViewDirection.x.negate()).normalize();
		var y = PositionNode.positionViewDirection.cross(x);
		return vec2(x.dot(NormalNode.transformedNormalView), y.dot(NormalNode.transformedNormalView)).mul(0.495).add(0.5); // 0.495 to remove artifacts caused by undersized matcap disks
	}

}

@:keep static var matcapUV = Node.nodeImmutable(MatcapUVNode);

Node.addNodeClass('MatcapUVNode', MatcapUVNode);