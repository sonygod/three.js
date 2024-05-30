import MaterialNode from './MaterialNode.js';
import { addNodeClass } from '../core/Node.js';
import { nodeImmutable } from '../shadernode/ShaderNode.js';

class InstancedPointsMaterialNode extends MaterialNode {

	public function setup( /*builder*/ ) {

		return this.getFloat( this.scope );

	}

}

InstancedPointsMaterialNode.POINT_WIDTH = 'pointWidth';

@:nodeImmutable(InstancedPointsMaterialNode, InstancedPointsMaterialNode.POINT_WIDTH)
export var materialPointWidth;

addNodeClass('InstancedPointsMaterialNode', InstancedPointsMaterialNode);