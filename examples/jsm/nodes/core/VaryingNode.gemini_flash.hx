import Node from "./Node";
import NodeShaderStage from "./constants";
import ShaderNode from "../shadernode/ShaderNode";

class VaryingNode extends Node {

	public node:Node;
	public name:String;

	public function new(node:Node, name:String = null) {
		super();
		this.node = node;
		this.name = name;
		this.isVaryingNode = true;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function getHash(builder:ShaderNode):String {
		return this.name != null ? this.name : super.getHash(builder);
	}

	public function getNodeType(builder:ShaderNode):String {
		// VaryingNode is auto type
		return this.node.getNodeType(builder);
	}

	public function setupVarying(builder:ShaderNode):Dynamic {
		var properties = builder.getNodeProperties(this);
		var varying = properties.varying;

		if (varying == null) {
			var name = this.name;
			var type = this.getNodeType(builder);
			properties.varying = varying = builder.getVaryingFromNode(this, name, type);
			properties.node = this.node;
		}

		// this property can be used to check if the varying can be optimized for a variable
		if (varying.needsInterpolation == null) {
			varying.needsInterpolation = (builder.shaderStage == "fragment");
		}

		return varying;
	}

	public function setup(builder:ShaderNode) {
		this.setupVarying(builder);
	}

	public function generate(builder:ShaderNode):String {
		var type = this.getNodeType(builder);
		var varying = this.setupVarying(builder);
		var propertyName = builder.getPropertyName(varying, NodeShaderStage.VERTEX);

		// force node run in vertex stage
		builder.flowNodeFromShaderStage(NodeShaderStage.VERTEX, this.node, type, propertyName);

		return builder.getPropertyName(varying);
	}
}

export default VaryingNode;

export var varying = ShaderNode.nodeProxy(VaryingNode);

ShaderNode.addNodeElement("varying", varying);

ShaderNode.addNodeClass("VaryingNode", VaryingNode);