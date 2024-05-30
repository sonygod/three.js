import three.js.examples.jsm.nodes.core.Node;

class LightingNode extends Node {

	public function new() {

		super('vec3');

	}

	public function generate():Void {

		trace('Abstract function.');

	}

}

addNodeClass('LightingNode', LightingNode);