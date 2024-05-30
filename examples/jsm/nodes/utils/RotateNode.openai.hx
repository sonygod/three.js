package three.js.examples.jsm.nodes.utils;

import three.js.core.TempNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;
import three.js.math.MathNode;

class RotateNode extends TempNode {
    public var positionNode:TempNode;
    public var rotationNode:TempNode;

    public function new(positionNode:TempNode, rotationNode:TempNode) {
        super();
        this.positionNode = positionNode;
        this.rotationNode = rotationNode;
    }

    public function getNodeType(builder:Dynamic):String {
        return positionNode.getNodeType(builder);
    }

    public function setup(builder:Dynamic):Dynamic {
        var nodeType = getNodeType(builder);
        var rotationNode = this.rotationNode;
        var positionNode = this.positionNode;

        if (nodeType == 'vec2') {
            var cosAngle = rotationNode.cos();
            var sinAngle = rotationNode.sin();
            var rotationMatrix = new math.Mat2(cosAngle, sinAngle, -sinAngle, cosAngle);
            return rotationMatrix.mul(positionNode);
        } else {
            var rotation = rotationNode;
            var rotationXMatrix = new math.Mat4(
                1.0, 0.0, 0.0, 0.0,
                0.0, Math.cos(rotation.x), -Math.sin(rotation.x), 0.0,
                0.0, Math.sin(rotation.x), Math.cos(rotation.x), 0.0,
                0.0, 0.0, 0.0, 1.0
            );
            var rotationYMatrix = new math.Mat4(
                Math.cos(rotation.y), 0.0, Math.sin(rotation.y), 0.0,
                0.0, 1.0, 0.0, 0.0,
                -Math.sin(rotation.y), 0.0, Math.cos(rotation.y), 0.0,
                0.0, 0.0, 0.0, 1.0
            );
            var rotationZMatrix = new math.Mat4(
                Math.cos(rotation.z), -Math.sin(rotation.z), 0.0, 0.0,
                Math.sin(rotation.z), Math.cos(rotation.z), 0.0, 0.0,
                0.0, 0.0, 1.0, 0.0,
                0.0, 0.0, 0.0, 1.0
            );
            return rotationXMatrix.mul(rotationYMatrix).mul(rotationZMatrix).mul(new math.Vec4(positionNode, 1.0)).xyz;
        }
    }
}

@:extern
class RotateNodeExtern {
    static public function rotate(positionNode:TempNode, rotationNode:TempNode):RotateNode {
        return new RotateNode(positionNode, rotationNode);
    }
}

Node.addNodeElement('rotate', RotateNodeExtern.rotate);
Node.addNodeClass('RotateNode', RotateNode);