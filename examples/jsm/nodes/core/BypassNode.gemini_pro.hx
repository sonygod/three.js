import Node from "./Node";
import ShaderNode from "../shadernode/ShaderNode";

class BypassNode extends Node {

	public var isBypassNode:Bool = true;
	public var outputNode:Node;
	public var callNode:Node;

	public function new(returnNode:Node, callNode:Node) {
		super();
		this.outputNode = returnNode;
		this.callNode = callNode;
	}

	public function getNodeType(builder:ShaderNode):String {
		return this.outputNode.getNodeType(builder);
	}

	public function generate(builder:ShaderNode):String {
		var snippet = this.callNode.build(builder, "void");
		if (snippet != "") {
			builder.addLineFlowCode(snippet);
		}
		return this.outputNode.build(builder);
	}
}

var bypass = ShaderNode.nodeProxy(BypassNode);

ShaderNode.addNodeElement("bypass", bypass);
ShaderNode.addNodeClass("BypassNode", BypassNode);