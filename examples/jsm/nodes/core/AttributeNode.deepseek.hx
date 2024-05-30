import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.VaryingNode.varying;
import three.js.examples.jsm.nodes.shadernode.ShaderNode.nodeObject;

class AttributeNode extends Node {

	public function new(attributeName:String, nodeType:String = null, defaultNode:Node = null) {
		super(nodeType);
		this.defaultNode = defaultNode;
		this._attributeName = attributeName;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function getHash(builder:Dynamic):String {
		return this.getAttributeName(builder);
	}

	public function getNodeType(builder:Dynamic):String {
		var nodeType = super.getNodeType(builder);
		if (nodeType == null) {
			var attributeName = this.getAttributeName(builder);
			if (builder.hasGeometryAttribute(attributeName)) {
				var attribute = builder.geometry.getAttribute(attributeName);
				nodeType = builder.getTypeFromAttribute(attribute);
			} else {
				nodeType = 'float';
			}
		}
		return nodeType;
	}

	public function setAttributeName(attributeName:String):AttributeNode {
		this._attributeName = attributeName;
		return this;
	}

	public function getAttributeName(builder:Dynamic = null):String {
		return this._attributeName;
	}

	public function generate(builder:Dynamic):String {
		var attributeName = this.getAttributeName(builder);
		var nodeType = this.getNodeType(builder);
		var geometryAttribute = builder.hasGeometryAttribute(attributeName);
		if (geometryAttribute == true) {
			var attribute = builder.geometry.getAttribute(attributeName);
			var attributeType = builder.getTypeFromAttribute(attribute);
			var nodeAttribute = builder.getAttribute(attributeName, attributeType);
			if (builder.shaderStage == 'vertex') {
				return builder.format(nodeAttribute.name, attributeType, nodeType);
			} else {
				var nodeVarying = varying(this);
				return nodeVarying.build(builder, nodeType);
			}
		} else {
			trace('AttributeNode: Vertex attribute "' + attributeName + '" not found on geometry.');
			var defaultNode = this.defaultNode;
			if (defaultNode != null) {
				return defaultNode.build(builder, nodeType);
			} else {
				return builder.generateConst(nodeType);
			}
		}
	}

}

static function attribute(name:String, nodeType:String, defaultNode:Node):Node {
	return nodeObject(new AttributeNode(name, nodeType, nodeObject(defaultNode)));
}

Node.addNodeClass('AttributeNode', AttributeNode);