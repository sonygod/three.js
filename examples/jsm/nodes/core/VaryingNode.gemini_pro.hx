import Node from "./Node";
import {NodeShaderStage} from "./constants";
import {addNodeElement, nodeProxy} from "../shadernode/ShaderNode";

class VaryingNode extends Node {
	public var node:Node;
	public var name:String;
	public var isVaryingNode:Bool = true;

	public function new(node:Node, name:String = null) {
		super();
		this.node = node;
		this.name = name;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function getHash(builder:Dynamic):String {
		return name != null ? name : super.getHash(builder);
	}

	public function getNodeType(builder:Dynamic):String {
		// VaryingNode is auto type
		return node.getNodeType(builder);
	}

	public function setupVarying(builder:Dynamic):Dynamic {
		var properties = builder.getNodeProperties(this);
		var varying = properties.varying;
		if (varying == null) {
			var name = this.name;
			var type = this.getNodeType(builder);
			properties.varying = varying = builder.getVaryingFromNode(this, name, type);
			properties.node = this.node;
		}
		// this property can be used to check if the varying can be optimized for a variable
		varying.needsInterpolation || (varying.needsInterpolation = (builder.shaderStage == "fragment"));
		return varying;
	}

	public function setup(builder:Dynamic):Void {
		setupVarying(builder);
	}

	public function generate(builder:Dynamic):String {
		var type = this.getNodeType(builder);
		var varying = setupVarying(builder);
		var propertyName = builder.getPropertyName(varying, NodeShaderStage.VERTEX);
		// force node run in vertex stage
		builder.flowNodeFromShaderStage(NodeShaderStage.VERTEX, this.node, type, propertyName);
		return builder.getPropertyName(varying);
	}
}

export default VaryingNode;

export var varying = nodeProxy(VaryingNode);

addNodeElement("varying", varying);

addNodeClass("VaryingNode", VaryingNode);