import Node from "./Node";
import VaryingNode from "./VaryingNode";
import ShaderNode from "../shadernode/ShaderNode";

class AttributeNode extends Node {
	public defaultNode: ShaderNode;
	private _attributeName: String;

	public function new(attributeName: String, nodeType: String = null, defaultNode: ShaderNode = null) {
		super(nodeType);
		this.defaultNode = defaultNode;
		this._attributeName = attributeName;
	}

	public function isGlobal(): Bool {
		return true;
	}

	public function getHash(builder: Dynamic): String {
		return this.getAttributeName(builder);
	}

	public function getNodeType(builder: Dynamic): String {
		var nodeType = super.getNodeType(builder);

		if (nodeType == null) {
			var attributeName = this.getAttributeName(builder);

			if (builder.hasGeometryAttribute(attributeName)) {
				var attribute = builder.geometry.getAttribute(attributeName);
				nodeType = builder.getTypeFromAttribute(attribute);
			} else {
				nodeType = "float";
			}
		}

		return nodeType;
	}

	public function setAttributeName(attributeName: String): AttributeNode {
		this._attributeName = attributeName;
		return this;
	}

	public function getAttributeName(builder: Dynamic): String {
		return this._attributeName;
	}

	public function generate(builder: Dynamic): String {
		var attributeName = this.getAttributeName(builder);
		var nodeType = this.getNodeType(builder);
		var geometryAttribute = builder.hasGeometryAttribute(attributeName);

		if (geometryAttribute) {
			var attribute = builder.geometry.getAttribute(attributeName);
			var attributeType = builder.getTypeFromAttribute(attribute);

			var nodeAttribute = builder.getAttribute(attributeName, attributeType);

			if (builder.shaderStage == "vertex") {
				return builder.format(nodeAttribute.name, attributeType, nodeType);
			} else {
				var nodeVarying = new VaryingNode(this);
				return nodeVarying.build(builder, nodeType);
			}
		} else {
			Sys.warning("AttributeNode: Vertex attribute \"" + attributeName + "\" not found on geometry.");

			var defaultNode = this.defaultNode;

			if (defaultNode != null) {
				return defaultNode.build(builder, nodeType);
			} else {
				return builder.generateConst(nodeType);
			}
		}
	}
}

export default AttributeNode;

export function attribute(name: String, nodeType: String, defaultNode: ShaderNode): ShaderNode {
	return new ShaderNode(new AttributeNode(name, nodeType, new ShaderNode(defaultNode)));
}

Node.addNodeClass("AttributeNode", AttributeNode);