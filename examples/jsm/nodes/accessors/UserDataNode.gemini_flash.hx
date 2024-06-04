import ReferenceNode from "./ReferenceNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class UserDataNode extends ReferenceNode {

	public var userData:Dynamic;

	public function new(property:String, inputType:Dynamic, userData:Dynamic = null) {
		super(property, inputType, userData);
		this.userData = userData;
	}

	override public function update(frame:Dynamic) {
		this.reference = this.userData != null ? this.userData : frame.object.userData;
		super.update(frame);
	}

}

export var userData = (name:String, inputType:Dynamic, userData:Dynamic) -> ShaderNode {
	return ShaderNode.nodeObject(new UserDataNode(name, inputType, userData));
};

Node.addNodeClass("UserDataNode", UserDataNode);