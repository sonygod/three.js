package three.js.examples.jsm.nodes.utils;

import three.js.core.TempNode;
import three.js.shadernode.ShaderNode;

class RotateUVNode extends TempNode {

    public var uvNode:ShaderNode;
    public var rotationNode:ShaderNode;
    public var centerNode:Vec2;

    public function new(uvNode:ShaderNode, rotationNode:ShaderNode, ?centerNode:Vec2) {
        super('vec2');
        this.uvNode = uvNode;
        this.rotationNode = rotationNode;
        if (centerNode == null) centerNode = new Vec2(0.5, 0.5);
        this.centerNode = centerNode;
    }

    override public function setup():ShaderNode {
        var vector:ShaderNode = new SubtractNode(uvNode, centerNode);
        return new AddNode(new RotateNode(vector, rotationNode), centerNode);
    }

}

extern class RotateNode extends ShaderNode {
    public function new(node:ShaderNode, rotation:ShaderNode);
}

extern class SubtractNode extends ShaderNode {
    public function new(a:ShaderNode, b:ShaderNode);
}

extern class AddNode extends ShaderNode {
    public function new(a:ShaderNode, b:ShaderNode);
}

extern class Vec2 {
    public var x:Float;
    public var y:Float;
    public function new(x:Float, y:Float);
}

class ShaderNode {
    public function new(type:String);
}

class TempNode extends ShaderNode {
    public function new(type:String);
}

// Register the node
ShaderNode.addNodeElement('rotateUV', nodeProxy(RotateUVNode));
ShaderNode.addNodeClass('RotateUVNode', RotateUVNode);