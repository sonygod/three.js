import Node from '../core/Node.hx';

@:isNode
class LightingNode extends Node {
	public function new() {
		super('vec3');
	}

	public function generate(/*builder*/) {
		trace('Abstract function.');
	}
}

class meta {
	public static function getNodeClass() {
		return LightingNode;
	}
}