package three.js.examples.jsg.nodes.display;

import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class FrontFacingNode extends Node {

    public var isFrontFacingNode:Bool;

    public function new() {
        super('bool');
        isFrontFacingNode = true;
    }

    override public function generate(builder:Dynamic) {
        var renderer:Dynamic = builder.renderer;
        var material:Dynamic = builder.material;

        if (renderer.coordinateSystem == WebGLCoordinateSystem.BACKSIDE) {
            if (material.side == BackSide) {
                return 'false';
            }
        }

        return builder.getFrontFacing();
    }

}

// Export the class
@:keep
@:native("FrontFacingNode")
class FrontFacingNode {}

// Create immutable node
var frontFacing:ShaderNode = ShaderNode.immutable(new FrontFacingNode());

// Create a new node based on the frontFacing node
var faceDirection:ShaderNode = new ShaderNode.float(frontFacing).mul(2.0).sub(1.0);

// Register the node class
ShaderNode.addClass("FrontFacingNode", FrontFacingNode);