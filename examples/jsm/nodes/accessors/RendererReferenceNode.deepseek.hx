import three.js.examples.jsm.nodes.accessors.ReferenceNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class RendererReferenceNode extends ReferenceNode {

	public function new(property:String, inputType:String, renderer:Dynamic = null) {
		super(property, inputType, renderer);
		this.renderer = renderer;
	}

	public function updateReference(state:Dynamic):Dynamic {
		this.reference = this.renderer !== null ? this.renderer : state.renderer;
		return this.reference;
	}

}

static function rendererReference(name:String, type:String, renderer:Dynamic):Dynamic {
	return ShaderNode.nodeObject(new RendererReferenceNode(name, type, renderer));
}

Node.addNodeClass('RendererReferenceNode', RendererReferenceNode);