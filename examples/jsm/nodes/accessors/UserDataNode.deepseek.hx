import ReferenceNode from './ReferenceNode.js';
import { addNodeClass } from '../core/Node.js';
import { nodeObject } from '../shadernode/ShaderNode.js';

class UserDataNode extends ReferenceNode {

	public function new(property:String, inputType:String, userData:Dynamic = null) {
		super(property, inputType, userData);
		this.userData = userData;
	}

	public function update(frame:Dynamic):Void {
		this.reference = this.userData !== null ? this.userData : frame.object.userData;
		super.update(frame);
	}

}

static function userData(name:String, inputType:String, userData:Dynamic):Dynamic {
	return nodeObject(new UserDataNode(name, inputType, userData));
}

addNodeClass('UserDataNode', UserDataNode);