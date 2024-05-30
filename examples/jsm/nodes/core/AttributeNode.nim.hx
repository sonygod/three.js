import Node, { addNodeClass } from './Node.js';
import { varying } from './VaryingNode.js';
import { nodeObject } from '../shadernode/ShaderNode.js';

class AttributeNode extends Node {

	public var defaultNode:Node;

	private var _attributeName:String;

	public function new(attributeName:String, nodeType:Null<Dynamic>, defaultNode:Null<Node>) {

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

		var nodeType:String = super.getNodeType(builder);

		if (nodeType == null) {

			var attributeName:String = this.getAttributeName(builder);

			if (builder.hasGeometryAttribute(attributeName)) {

				var attribute:Dynamic = builder.geometry.getAttribute(attributeName);

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

	public function getAttributeName(/*builder:Dynamic*/):String {

		return this._attributeName;

	}

	public function generate(builder:Dynamic):String {

		var attributeName:String = this.getAttributeName(builder);
		var nodeType:String = this.getNodeType(builder);
		var geometryAttribute:Bool = builder.hasGeometryAttribute(attributeName);

		if (geometryAttribute) {

			var attribute:Dynamic = builder.geometry.getAttribute(attributeName);
			var attributeType:String = builder.getTypeFromAttribute(attribute);

			var nodeAttribute:Dynamic = builder.getAttribute(attributeName, attributeType);

			if (builder.shaderStage == 'vertex') {

				return builder.format(nodeAttribute.name, attributeType, nodeType);

			} else {

				var nodeVarying:Dynamic = varying(this);

				return nodeVarying.build(builder, nodeType);

			}

		} else {

			trace.warn( 'AttributeNode: Vertex attribute "${ attributeName }" not found on geometry.' );

			var defaultNode:Node = this.defaultNode;

			if (defaultNode != null) {

				return defaultNode.build(builder, nodeType);

			} else {

				return builder.generateConst(nodeType);

			}

		}

	}

}

export default AttributeNode;

export function attribute(name:String, nodeType:Dynamic, defaultNode:Node):Node {

	return nodeObject(new AttributeNode(name, nodeType, nodeObject(defaultNode)));

}

addNodeClass('AttributeNode', AttributeNode);