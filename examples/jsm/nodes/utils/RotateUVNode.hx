package three.js.examples.jsm.nodes.utils;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class RotateUVNode extends TempNode {

    public var uvNode:Dynamic;
    public var rotationNode:Dynamic;
    public var centerNode:Vec2;

    public function new(uvNode:Dynamic, rotationNode:Dynamic, ?centerNode:Vec2 = new Vec2(0.5, 0.5)) {
        super('vec2');

        this.uvNode = uvNode;
        this.rotationNode = rotationNode;
        this.centerNode = centerNode;
    }

    public function setup():Vec2 {
        var vector = uvNode.sub(centerNode);
        return vector.rotate(rotationNode).add(centerNode);
    }

}

// Export the RotateUVNode class
@:expose
class RotateUVNodeProxy {
    public static function rotateUV(uvNode:Dynamic, rotationNode:Dynamic, ?centerNode:Vec2 = new Vec2(0.5, 0.5)) {
        return new RotateUVNode(uvNode, rotationNode, centerNode);
    }
}

// Register the RotateUVNode class with the Node system
Node.addNodeElement('rotateUV', RotateUVNodeProxy.rotateUV);
Node.addNodeClass('RotateUVNode', RotateUVNode);