import TempNode from 'three.js.nodes.core.TempNode';
import Node from 'three.js.nodes.core.Node';
import { ShaderNode, vec2 } from 'three.js.nodes.shadernode.ShaderNode';

class RotateUVNode extends TempNode {

    public var uvNode:ShaderNode;
    public var rotationNode:ShaderNode;
    public var centerNode:ShaderNode;

    public function new(uvNode:ShaderNode, rotationNode:ShaderNode, centerNode:ShaderNode = vec2(0.5)) {
        super('vec2');

        this.uvNode = uvNode;
        this.rotationNode = rotationNode;
        this.centerNode = centerNode;
    }

    public function setup():ShaderNode {
        var vector = uvNode.sub(centerNode);
        return vector.rotate(rotationNode).add(centerNode);
    }
}

class RotateUV {
    public static function call(uvNode:ShaderNode, rotationNode:ShaderNode, centerNode:ShaderNode = vec2(0.5)):ShaderNode {
        return new RotateUVNode(uvNode, rotationNode, centerNode);
    }
}

ShaderNode.addNodeElement('rotateUV', RotateUV.call);
Node.addNodeClass('RotateUVNode', RotateUVNode);