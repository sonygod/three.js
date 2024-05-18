package three.js.examples.jsm.nodes.lighting;

import three.js.examples.jsm.nodes.LightingNode;

class IrradianceNode extends LightingNode {

    public var node:Dynamic;

    public function new(node:Dynamic) {
        super();
        this.node = node;
    }

    public function setup(builder:Dynamic) {
        builder.context.irradiance.addAssign(node);
    }

}

// Register the node class
three.js.core.Node.addNodeClass('IrradianceNode', IrradianceNode);