import LightingNode from './LightingNode.hx';
import { addNodeClass } from '../core/Node.hx';

class IrradianceNode extends LightingNode {

	public function new(node:Dynamic) {
		super();
		this.node = node;
	}

	public function setup(builder:Dynamic) {
		builder.context.irradiance.addAssign(this.node);
	}

}

addNodeClass('IrradianceNode', IrradianceNode);