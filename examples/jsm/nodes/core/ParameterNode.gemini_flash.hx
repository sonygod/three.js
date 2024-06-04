import Node from "./Node";
import ShaderNode from "../shadernode/ShaderNode";

class ParameterNode extends Node {

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

var parameter = (type:String, name:String) -> ShaderNode.nodeObject(new ParameterNode(type, name));

Node.addNodeClass("ParameterNode", ParameterNode);