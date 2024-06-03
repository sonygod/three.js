import jsm.core.Node;
import jsm.core.TempNode;
import jsm.nodes.accessors.CameraNode;
import jsm.nodes.accessors.ModelNode;
import jsm.nodes.accessors.PositionNode;
import jsm.shadernode.ShaderNode;
import jsm.core.VaryingNode;

class ModelViewProjectionNode extends TempNode {

    public var positionNode: jsm.nodes.Node.Node;

    public function new(positionNode: jsm.nodes.Node.Node = null) {
        super("vec4");
        this.positionNode = positionNode;
    }

    override public function setup(builder: jsm.core.NodeBuilder.NodeBuilder): jsm.nodes.Node.Node {
        if (builder.shaderStage == 'fragment') {
            return VaryingNode.varying(builder.context.mvp);
        }

        var position: jsm.nodes.Node.Node = this.positionNode != null ? this.positionNode : PositionNode.positionLocal;

        return CameraNode.cameraProjectionMatrix.mul(ModelNode.modelViewMatrix).mul(position);
    }
}

export default ModelViewProjectionNode;

@:expose
static function modelViewProjection(positionNode: jsm.nodes.Node.Node = null): jsm.nodes.Node.Node {
    return ShaderNode.nodeProxy(new ModelViewProjectionNode(positionNode));
}

Node.addNodeClass('ModelViewProjectionNode', ModelViewProjectionNode);