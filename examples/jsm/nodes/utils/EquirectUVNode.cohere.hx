import TempNode from '../core/TempNode.hx';
import { positionWorldDirection } from '../accessors/PositionNode.hx';
import { nodeProxy, vec2 } from '../shadernode/ShaderNode.hx';
import { addNodeClass } from '../core/Node.hx';

class EquirectUVNode extends TempNode {

	public function new( dirNode : Dynamic = positionWorldDirection ) {

		super('vec2');

		this.dirNode = dirNode;

	}

	public function setup() : vec2 {

		var dir = this.dirNode;

		var u = Math.atan2(dir.z, dir.x) * (1.0 / (Math.PI * 2.0)) + 0.5;
		var v = Math.clamp(dir.y, -1.0, 1.0).asin() * (1.0 / Math.PI) + 0.5;

		return vec2(u, v);

	}

}

@:private static var _equirectUVNode = null;

static public function equirectUV() : EquirectUVNode {

	if (_equirectUVNode == null) {

		_equirectUVNode = EquirectUVNode.create();

	}

	return _equirectUVNode;

}

static public function __init__() {

	addNodeClass('EquirectUVNode', EquirectUVNode);

}