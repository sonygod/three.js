import LightingNode from './LightingNode.js';
import { addNodeClass } from '../core/Node.js';

class AONode extends LightingNode {

	public function new(aoNode:Null<AONode> = null) {
		super();
		this.aoNode = aoNode;
	}

	public function setup(builder:Builder) {
		var aoIntensity:Float = 1.0;
		var aoNode:Float = this.aoNode.x - 1.0 * aoIntensity + 1.0;
		builder.context.ambientOcclusion *= aoNode;
	}

}

addNodeClass('AONode', AONode);