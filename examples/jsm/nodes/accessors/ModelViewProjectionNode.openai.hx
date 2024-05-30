package three.js.examples.jsm.nodes.accessors;

import three.js.core.Node;
import three.js.core.TempNode;
import three.js.nodes.CameraNode;
import three.js.nodes.ModelNode;
import three.js.nodes.PositionNode;
import three.js.shadernode.ShaderNode;
import three.js.core.VaryingNode;

class ModelViewProjectionNode extends TempNode {
    public var positionNode:Node;

    public function new(positionNode:Node = null) {
        super('vec4');
        this.positionNode = positionNode;
    }

    public function setup(builder:Dynamic):Dynamic {
        if (builder.shaderStage == 'fragment') {
            return varying(builder.context.mvp);
        }
        var position:Node = this.positionNode != null ? this.positionNode : PositionNode.positionLocal;
        return CameraNode.cameraProjectionMatrix.mul(ModelNode.modelViewMatrix).mul(position);
    }
}

extern class ModelViewProjectionNodeProxy {
    public static var modelViewProjection:Node;
}

ModelViewProjectionNodeProxy.modelViewProjection = ShaderNode.nodeProxy(ModelViewProjectionNode);

Node.addNodeClass('ModelViewProjectionNode', ModelViewProjectionNode);