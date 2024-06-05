import ReferenceNode from "./ReferenceNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class UserDataNode extends ReferenceNode {

	public var userData:Dynamic;

	public function new(property:String, inputType:String, userData:Dynamic = null) {
		super(property, inputType, userData);
		this.userData = userData;
	}

	override public function update(frame:Dynamic):Void {
		this.reference = if (this.userData != null) this.userData else frame.object.userData;
		super.update(frame);
	}

}

export function userData(name:String, inputType:String, userData:Dynamic):ShaderNode {
	return new ShaderNode(new UserDataNode(name, inputType, userData));
}

Node.addNodeClass("UserDataNode", UserDataNode);