import ReferenceNode from './ReferenceNode.js';
//import { renderGroup } from '../core/UniformGroupNode.js';
//import { NodeUpdateType } from '../core/constants.js';
import { addNodeClass } from '../core/Node.js';
import { nodeObject } from '../shadernode/ShaderNode.js';

class MaterialReferenceNode extends ReferenceNode {

	public var material:Dynamic;

	public function new(property:Dynamic, inputType:Dynamic, material:Dynamic = null) {
		super(property, inputType, material);

		this.material = material;

		//this.updateType = NodeUpdateType.RENDER;
	}

	/*public function setNodeType(node:Dynamic) {
		super.setNodeType(node);

		this.node.groupNode = renderGroup;
	}*/

	public function updateReference(state:Dynamic):Dynamic {
		this.reference = this.material !== null ? this.material : state.material;

		return this.reference;
	}
}

export default MaterialReferenceNode;

export function materialReference(name:String, type:Dynamic, material:Dynamic):Dynamic {
	return nodeObject(new MaterialReferenceNode(name, type, material));
}

addNodeClass('MaterialReferenceNode', MaterialReferenceNode);