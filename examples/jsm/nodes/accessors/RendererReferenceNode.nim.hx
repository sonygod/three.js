import ReferenceNode from './ReferenceNode.js';
import { addNodeClass } from '../core/Node.js';
import { nodeObject } from '../shadernode/ShaderNode.js';

class RendererReferenceNode extends ReferenceNode {

	public var renderer:Null<Dynamic>;

	public function new(property:String, inputType:String, renderer:Null<Dynamic> = null) {
		super(property, inputType, renderer);
		this.renderer = renderer;
	}

	public function updateReference(state:Dynamic):Dynamic {
		this.reference = this.renderer != null ? this.renderer : state.renderer;
		return this.reference;
	}

}

export default RendererReferenceNode;

export function rendererReference(name:String, type:String, renderer:Null<Dynamic>):Dynamic {
	return nodeObject(new RendererReferenceNode(name, type, renderer));
}

addNodeClass('RendererReferenceNode', RendererReferenceNode);