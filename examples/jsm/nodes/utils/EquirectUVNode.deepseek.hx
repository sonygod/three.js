import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.accessors.PositionNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.core.Node;

class EquirectUVNode extends TempNode {

	public function new(dirNode:positionWorldDirection = positionWorldDirection) {
		super('vec2');
		this.dirNode = dirNode;
	}

	public function setup():vec2 {
		var dir = this.dirNode;
		var u = dir.z.atan2(dir.x).mul(1 / (Math.PI * 2)).add(0.5);
		var v = dir.y.clamp(-1.0, 1.0).asin().mul(1 / Math.PI).add(0.5);
		return vec2(u, v);
	}

}

static function equirectUV(node:EquirectUVNode):EquirectUVNode {
	return nodeProxy(node);
}

Node.addNodeClass('EquirectUVNode', EquirectUVNode);