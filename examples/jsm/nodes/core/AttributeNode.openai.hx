package three.js.nodes.core;

import Node;
import varying.VaryingNode;
import shaderNode.ShaderNode;

class AttributeNode extends Node {
	
	var defaultNode:Node;
	var _attributeName:String;

	public function new(attributeName:String, nodeType:Null<NodeType> = null, defaultNode:Null<Node> = null) {
		super(nodeType);
		this.defaultNode = defaultNode;
		_attributeName = attributeName;
	}

	public function isGlobal():Bool {
		return true;
	}

	public function getHash(builder:ShaderNode.Builder):String {
		return getAttributeName(builder);
	}

	public function getNodeType(builder:ShaderNode.Builder):NodeType {
		var nodeType:NodeType = super.getNodeType(builder);
		if (nodeType == null) {
			var attributeName:String = getAttributeName(builder);
			if (builder.hasGeometryAttribute(attributeName)) {
				var attribute:GeometryAttribute = builder.geometry.getAttribute(attributeName);
				nodeType = builder.getTypeFromAttribute(attribute);
			} else {
				nodeType = FLOAT;
			}
		}
		return nodeType;
	}

	public function setAttributeName(attributeName:String):AttributeNode {
		_attributeName = attributeName;
		return this;
	}

	public function getAttributeName(builder:ShaderNode.Builder):String {
		return _attributeName;
	}

	public function generate(builder:ShaderNode.Builder):String {
		var attributeName:String = getAttributeName(builder);
		var nodeType:NodeType = getNodeType(builder);
		var geometryAttribute:Bool = builder.hasGeometryAttribute(attributeName);
		if (geometryAttribute) {
			var attribute:GeometryAttribute = builder.geometry.getAttribute(attributeName);
			var attributeType:NodeType = builder.getTypeFromAttribute(attribute);
			var nodeAttribute:ShaderNode = builder.getAttribute(attributeName, attributeType);
			if (builder.shaderStage == 'vertex') {
				return builder.format(nodeAttribute.name, attributeType, nodeType);
			} else {
				var nodeVarying:VaryingNode = VaryingNode.fromNode(this);
				return nodeVarying.build(builder, nodeType);
			}
		} else {
			Console.warn('AttributeNode: Vertex attribute "$attributeName" not found on geometry.');
			if (defaultNode != null) {
				return defaultNode.build(builder, nodeType);
			} else {
				return builder.generateConst(nodeType);
			}
		}
	}

	public static function attribute(name:String, nodeType:Null<NodeType> = null, defaultNode:Null<Node> = null):ShaderNode {
		var node:AttributeNode = new AttributeNode(name, nodeType, defaultNode);
		return ShaderNode.nodeObject(node);
	}
}