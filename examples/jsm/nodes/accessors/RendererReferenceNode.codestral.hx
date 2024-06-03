import ReferenceNode;
import Node;
import ShaderNode;

class RendererReferenceNode extends ReferenceNode {

    public var renderer:Any;

    public function new(property:Any, inputType:Any, renderer:Any = null) {
        super(property, inputType, renderer);
        this.renderer = renderer;
    }

    public function updateReference(state:Any):Any {
        this.reference = (this.renderer != null) ? this.renderer : state.renderer;
        return this.reference;
    }
}

function rendererReference(name:String, type:Any, renderer:Any):Any {
    return ShaderNode.nodeObject(new RendererReferenceNode(name, type, renderer));
}

Node.addNodeClass('RendererReferenceNode', RendererReferenceNode);