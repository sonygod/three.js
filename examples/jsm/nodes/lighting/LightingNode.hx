package three.js.examples.jsm.nodes.lighting;

import three.core.Node;

class LightingNode extends Node {

	public function new() {
		super('vec3');
	}

	override public function generate(builder:Dynamic) {
		trace('Abstract function.');
	}

}

registerNodeClass('LightingNode', LightingNode);