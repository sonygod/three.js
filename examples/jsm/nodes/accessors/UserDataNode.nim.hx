import ReferenceNode from './ReferenceNode.js';
import { addNodeClass } from '../core/Node.js';
import { nodeObject } from '../shadernode/ShaderNode.js';

class UserDataNode extends ReferenceNode {

	public var userData:Dynamic;

	public function new(property:String, inputType:String, userData:Dynamic = null) {

		super(property, inputType, userData);

		this.userData = userData;

	}

	public function update(frame:Dynamic) {

		this.reference = this.userData !== null ? this.userData : frame.object.userData;

		super.update(frame);

	}

}

export default UserDataNode;

export function userData(name:String, inputType:String, userData:Dynamic) {
	return nodeObject(new UserDataNode(name, inputType, userData));
}

addNodeClass('UserDataNode', UserDataNode);