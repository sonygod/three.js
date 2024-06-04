import ReferenceNode from "./ReferenceNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class RendererReferenceNode extends ReferenceNode {
	public var renderer:Dynamic;

	public function new(property:String, inputType:Dynamic, renderer:Dynamic = null) {
		super(property, inputType, renderer);
		this.renderer = renderer;
	}

	public function updateReference(state:Dynamic):Dynamic {
		this.reference = if (this.renderer != null) this.renderer else state.renderer;
		return this.reference;
	}
}

export function rendererReference(name:String, type:Dynamic, renderer:Dynamic):ShaderNode {
	return ShaderNode.nodeObject(new RendererReferenceNode(name, type, renderer));
}

Node.addNodeClass("RendererReferenceNode", RendererReferenceNode);