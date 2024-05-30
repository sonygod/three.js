import Node from './Node.hx';
import { NodeShaderStage } from './constants.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class VaryingNode extends Node {
	public var node: Node;
	public var name: String;

	public function new(node: Node, name: String = null) {
		super();
		this.node = node;
		this.name = name;
		this.isVaryingNode = true;
	}

	public function isGlobal(): Bool {
		return true;
	}

	public function getHash(builder: Dynamic): Int {
		return if (this.name != null) this.name.hashCode() else super.getHash(builder);
	}

	public function getNodeType(builder: Dynamic): Int {
		return this.node.getNodeType(builder);
	}

	public function setupVarying(builder: Dynamic): Dynamic {
		var properties = builder.getNodeProperties(this);
		var varying = properties.varying;

		if (varying == null) {
			var name = this.name;
			var type = this.getNodeType(builder);

			properties.varying = varying = builder.getVaryingFromNode(this, name, type);
			properties.node = this.node;
		}

		varying.needsInterpolation = varying.needsInterpolation || (builder.shaderStage == NodeShaderStage.Fragment);

		return varying;
	}

	public function setup(builder: Dynamic): Void {
		this.setupVarying(builder);
	}

	public function generate(builder: Dynamic): String {
		var type = this.getNodeType(builder);
		var varying = this.setupVarying(builder);

		var propertyName = builder.getPropertyName(varying, NodeShaderStage.Vertex);

		builder.flowNodeFromShaderStage(NodeShaderStage.Vertex, this.node, type, propertyName);

		return builder.getPropertyName(varying);
	}
}

@:export(varying)
static function varying(node: Node, name: String = null): VaryingNode {
	return new VaryingNode(node, name);
}

addNodeElement('varying', nodeProxy(VaryingNode));

addNodeClass('VaryingNode', VaryingNode);