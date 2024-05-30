package three.js.examples.jsm.nodes.lighting;

import three.js.core.Node;

class LightingNode extends Node {
    public function new() {
        super('vec3');
    }

    public function generate(builder:Dynamic) {
        trace('Abstract function.');
    }
}

registerNodeType('LightingNode', LightingNode);