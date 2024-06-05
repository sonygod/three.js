import Node from "./Node";
import ShaderNode from "../shadernode/ShaderNode";
import PropertyNode from "./PropertyNode";

class ParameterNode extends PropertyNode {

	public var isParameterNode:Bool;

	public function new(nodeType:String, name:String = null) {
		super(nodeType, name);
		this.isParameterNode = true;
	}

	public function getHash():String {
		return this.uuid;
	}

	public function generate():String {
		return this.name;
	}

}

class ParameterNodeObject extends ShaderNode {

	public function new(type:String, name:String) {
		super(new ParameterNode(type, name));
	}

}

export function parameter(type:String, name:String) : ParameterNodeObject {
	return new ParameterNodeObject(type, name);
}

Node.addNodeClass("ParameterNode", ParameterNode);