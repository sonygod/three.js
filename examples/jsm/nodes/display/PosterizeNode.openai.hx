package three.js.examples.jsm.nodes.display;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.shader.ShaderNode;

class PosterizeNode extends TempNode {

    public var sourceNode:Node;
    public var stepsNode:Node;

    public function new(sourceNode:Node, stepsNode:Node) {
        super();
        this.sourceNode = sourceNode;
        this.stepsNode = stepsNode;
    }

    override public function setup():Node {
        return sourceNode.mul(stepsNode).floor().div(stepsNode);
    }

}

// Add node to registry
ShaderNode.addNodeElement("posterize", NodeProxy.getNodeProxy(PosterizeNode));
Node.addClass("PosterizeNode", PosterizeNode);

// Expose as default export
#if haxe4
@:native("posterize") extern public static var posterize:Dynamic;
#else
extern public static var posterize:Dynamic;
#end