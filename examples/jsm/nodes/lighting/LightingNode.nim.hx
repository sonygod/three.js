import Node, { addNodeClass } from '../core/Node.hx';

class LightingNode extends Node {

	public function new() {

		super('vec3');

	}

	public function generate() {

		trace.warn('Abstract function.');

	}

}

export default LightingNode;

addNodeClass('LightingNode', LightingNode);