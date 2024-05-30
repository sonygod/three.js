import ReferenceNode from './ReferenceNode.js';
//import { renderGroup } from '../core/UniformGroupNode.js';
//import { NodeUpdateType } from '../core/constants.js';
import { addNodeClass } from '../core/Node.js';
import { nodeObject } from '../shadernode/ShaderNode.js';

class MaterialReferenceNode extends ReferenceNode {

	public function new(property:String, inputType:String, material:Material = null) {

		super(property, inputType, material);

		this.material = material;

		//this.updateType = NodeUpdateType.RENDER;

	}

	/*public function setNodeType(node:Node) {

		super.setNodeType(node);

		this.node.groupNode = renderGroup;

	}*/

	public function updateReference(state:State) {

		this.reference = this.material !== null ? this.material : state.material;

		return this.reference;

	}

}

static function materialReference(name:String, type:String, material:Material) {
	return nodeObject(new MaterialReferenceNode(name, type, material));
}

addNodeClass('MaterialReferenceNode', MaterialReferenceNode);