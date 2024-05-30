package three.js.nodes.math;

import three.js.nodes.Node;
import three.js.nodes.ShaderNode;

class HashNode extends Node {

    public var seedNode:Node;

    public function new(seedNode:Node) {
        super();
        this.seedNode = seedNode;
    }

    public function setup(builder:Dynamic):Float {
        // Taken from https://www.shadertoy.com/view/XlGcRh, originally from pcg-random.org

        var state:Int = this.seedNode.toFloat().toInt() * 747796405 + 2891336453;
        var word:Int = (state >> (state >> 28) + 4) ^ state * 277803737;
        var result:Int = (word >> 22) ^ word;

        return result / Math.pow(2, 32); // Convert to range [0, 1)
    }

}

// Register the node
ShaderNode.nodeProxy("hash", HashNode);
Node.addNodeClass("HashNode", HashNode);