package three.js.examples.jsm.nodes.display;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class PosterizeNode extends TempNode {

    public var sourceNode:TempNode;
    public var stepsNode:TempNode;

    public function new(sourceNode:TempNode, stepsNode:TempNode) {
        super();
        this.sourceNode = sourceNode;
        this.stepsNode = stepsNode;
    }

    public function setup():TempNode {
        return sourceNode.mul(stepsNode).floor().div(stepsNode);
    }

}

// Register the node class
Node.addNodeClass('PosterizeNode', PosterizeNode);

// Register the node element
ShaderNode.addNodeElement('posterize', ShaderNode.nodeProxy(PosterizeNode));