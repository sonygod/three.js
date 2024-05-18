package three.js.examples.jsm.nodes.fog;

import three.js.examples.jsm.nodes.FogNode;
import three.js.examples.jsm.math.MathNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class FogRangeNode extends FogNode {

    public var isFogRangeNode:Bool = true;

    public var nearNode:Node;
    public var farNode:Node;

    public function new(colorNode:Node, nearNode:Node, farNode:Node) {
        super(colorNode);
        this.nearNode = nearNode;
        this.farNode = farNode;
    }

    public function setup(builder:Dynamic):Node {
        var viewZ:Node = getViewZNode(builder);
        return smoothstep(this.nearNode, this.farNode, viewZ);
    }
}

typedef FogRangeNodeProxy = nodeProxy<FogRangeNode>;

// Export the node class
@:export
class FogRangeNodeProxy extends FogRangeNodeProxy {}

// Register the node element
@:nodeElement
class FogRangeNodeElement {
    public function new() {}
}

// Register the node class
@:nodeClass
class FogRangeNodeClass {
    public function new() {}
}