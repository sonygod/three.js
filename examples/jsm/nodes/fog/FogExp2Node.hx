package three.js.examples.jsm.nodes.fog;

import three.js.examples.jsm.nodes.FogNode;

class FogExp2Node extends FogNode {
    public var isFogExp2Node:Bool = true;
    public var densityNode:Node;

    public function new(colorNode:Node, densityNode:Node) {
        super(colorNode);
        this.densityNode = densityNode;
    }

    public function setup(builder:Dynamic):Node {
        var viewZ = getViewZNode(builder);
        var density = densityNode;
        return density.mul(density, viewZ, viewZ).negate().exp().oneMinus();
    }
}

// Export the class
extern class FogExp2Node {
    public function new(colorNode:Node, densityNode:Node);
    public function setup(builder:Dynamic):Node;
}

// Register the node class
@:keep
@:native("densityFog")
extern class DensityFogNode extends FogExp2Node {
    public function new(colorNode:Node, densityNode:Node);
    public function setup(builder:Dynamic):Node;
}

// Register the node element
@:keep
@:native("densityFog")
extern class DensityFogElement {
    public function new();
}

// Add the node element to the registry
@:keep
@:native("addNodeElement")
extern function addNodeElement(name:String, node:Dynamic):Void;

// Add the node class to the registry
@:keep
@:native("addNodeClass")
extern function addNodeClass(name:String, nodeClass:Dynamic):Void;

// Initialize the node registry
addNodeElement("densityFog", DensityFogNode);
addNodeClass("FogExp2Node", FogExp2Node);