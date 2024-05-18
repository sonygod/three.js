package three.js.examples.jm.nodes.accessors;

import three.js.core.Node;
import three.js.core.TempNode;
import three.js.nodes.CameraNode;
import three.js.nodes.ModelNode;
import three.js.nodes.PositionNode;
import three.js.shadernode.ShaderNode;
import three.js.core.VaryingNode;

class ModelViewProjectionNode extends TempNode {

    public var positionNode:Node;

    public function new(?positionNode:Node) {
        super('vec4');

        this.positionNode = positionNode;
    }

    public function setup(builder:Dynamic):Node {
        if (builder.shaderStage == 'fragment') {
            return VaryingNode.varying(builder.context.mvp);
        }

        var position:Node = if (this.positionNode != null) this.positionNode else PositionNode.positionLocal;
        return CameraNode.cameraProjectionMatrix.mul(ModelNode.modelViewMatrix).mul(position);
    }

    public static function modelViewProjection():Node {
        return ShaderNode.nodeProxy(new ModelViewProjectionNode());
    }
}

Node.addNodeClass('ModelViewProjectionNode', ModelViewProjectionNode);