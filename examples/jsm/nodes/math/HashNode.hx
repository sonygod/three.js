package three.js.examples.jsm.nodes.math;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class HashNode extends Node {

    public var seedNode:Node;

    public function new(seedNode:Node) {
        super();
        this.seedNode = seedNode;
    }

    public function setup(builder:Null<Dynamic>):Float {
        // Taken from https://www.shadertoy.com/view/XlGcRh, originally from pcg-random.org

        var state:Int = this.seedNode.toUint() * 747796405 + 2891336453;
        var word:Int = (state >> 28) + 4 ^ state;
        word = (word >> state >> 28) + 4 ^ state;
        var result:Int = (word >> 22) ^ word;

        return (result / Math.pow(2, 32));
    }
}

// Expose the class
extern class HashNode {
    public function new(seedNode:Node);
    public function setup(builder:Null<Dynamic>):Float;
}

// Create a node proxy
var hash = ShaderNode.nodeProxy(HashNode);

// Register the node element
ShaderNode.addNodeElement('hash', hash);

// Register the node class
Node.addNodeClass('HashNode', HashNode);