import js.Node.addNodeClass;

import js.shadernode.ShaderNode.nodeObject;

import js.PropertyNode;

class ParameterNode extends js.PropertyNode {
	public var isParameterNode:Bool = true;

	public function new(nodeType:String, name:String) {
		super(nodeType, name);
	}

	public function getHash():String {
		return this.uuid;
	}

	public function generate():String {
		return this.name;
	}
}

@:expose("parameter")
static public function parameter(type:String, name:String):ParameterNode {
	return nodeObject(new ParameterNode(type, name));
}

addNodeClass('ParameterNode', ParameterNode);