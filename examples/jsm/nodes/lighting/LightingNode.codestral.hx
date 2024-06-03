import Node from '../core/Node';
import NodeUtils from '../utils/NodeUtils';

class LightingNode extends Node {

    public function new() {
        super('vec3');
    }

    public function generate(builder:Dynamic) {
        trace('Abstract function.');
    }
}

class Main {
    static function main() {
        NodeUtils.addNodeClass('LightingNode', Type.getClass<LightingNode>());
    }
}