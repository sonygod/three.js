package three.js.examples.jsm.nodes.lighting;

import three.js.examples.jsm.nodes.LightingNode;

class AONode extends LightingNode {
    public var aoNode:Dynamic;

    public function new(?aoNode:Dynamic) {
        super();
        this.aoNode = aoNode;
    }

    public function setup(builder:Dynamic) {
        var aoIntensity:Float = 1;
        var aoNode:Dynamic = this.aoNode.x.sub(1.0).mul(aoIntensity).add(1.0);
        builder.context.ambientOcclusion.mulAssign(aoNode);
    }
}

// Register the node class
Node.addNodeClass('AONode', AONode);