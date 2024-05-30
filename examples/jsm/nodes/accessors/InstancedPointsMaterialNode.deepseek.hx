import MaterialNode from './MaterialNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { nodeImmutable } from '../shadernode/ShaderNode.hx';

class InstancedPointsMaterialNode extends MaterialNode {

	public function new() {
		super();
	}

	public function setup(builder:Dynamic):Float {
		return this.getFloat(this.scope);
	}

}

static var POINT_WIDTH = 'pointWidth';

static function materialPointWidth(node:InstancedPointsMaterialNode):Dynamic {
	return nodeImmutable(node, InstancedPointsMaterialNode.POINT_WIDTH);
}

addNodeClass('InstancedPointsMaterialNode', InstancedPointsMaterialNode);