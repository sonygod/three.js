package three.js.examples.jsm.nodes.utils;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.math.MathNode;

class RotateNode extends TempNode {

    public var positionNode:Dynamic;
    public var rotationNode:Dynamic;

    public function new(positionNode:Dynamic, rotationNode:Dynamic) {
        super();
        this.positionNode = positionNode;
        this.rotationNode = rotationNode;
    }

    override public function getNodeType(builder:Dynamic):String {
        return positionNode.getNodeType(builder);
    }

    override public function setup(builder:Dynamic):Dynamic {
        var nodeType = getNodeType(builder);
        if (nodeType == 'vec2') {
            var cosAngle:Float = rotationNode.cos();
            var sinAngle:Float = rotationNode.sin();
            var rotationMatrix = new Mat2(cosAngle, sinAngle, -sinAngle, cosAngle);
            return rotationMatrix.mul(positionNode);
        } else {
            var rotation = rotationNode;
            var rotationXMatrix = new Mat4(
                1.0, 0.0, 0.0, 0.0,
                0.0, Math.cos(rotation.x), -Math.sin(rotation.x), 0.0,
                0.0, Math.sin(rotation.x), Math.cos(rotation.x), 0.0,
                0.0, 0.0, 0.0, 1.0
            );
            var rotationYMatrix = new Mat4(
                Math.cos(rotation.y), 0.0, Math.sin(rotation.y), 0.0,
                0.0, 1.0, 0.0, 0.0,
                -Math.sin(rotation.y), 0.0, Math.cos(rotation.y), 0.0,
                0.0, 0.0, 0.0, 1.0
            );
            var rotationZMatrix = new Mat4(
                Math.cos(rotation.z), -Math.sin(rotation.z), 0.0, 0.0,
                Math.sin(rotation.z), Math.cos(rotation.z), 0.0, 0.0,
                0.0, 0.0, 1.0, 0.0,
                0.0, 0.0, 0.0, 1.0
            );
            return rotationXMatrix.mul(rotationYMatrix).mul(rotationZMatrix).mul(new Vec4(positionNode, 1.0)).xyz;
        }
    }
}

@:keep
@:expose
extern class RotateNode {}

@:keep
@:expose
extern function rotate(node:RotateNode):Dynamic {
    return nodeProxy(RotateNode);
}

addNodeElement('rotate', rotate);

addNodeClass('RotateNode', RotateNode);