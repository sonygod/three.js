import Node from './Node.hx';
import { varying } from './VaryingNode.hx';
import { nodeObject } from '../shadernode/ShaderNode.hx';

class AttributeNode extends Node {
    public var defaultNode: Node;
    private var _attributeName: String;

    public function new(attributeName: String, nodeType: Node = null, defaultNode: Node = null) {
        super(nodeType);
        this.defaultNode = defaultNode;
        this._attributeName = attributeName;
    }

    public function isGlobal(): Bool {
        return true;
    }

    public function getHash(builder: Dynamic): Int {
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
                nodeType = 'Float';
            }
        }
        return nodeType;
    }

    public function setAttributeName(attributeName: String): Void {
        this._attributeName = attributeName;
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

@:export(default)
public function get_AttributeNode(): AttributeNode {
    return AttributeNode;
}

@:export
public function attribute(name: String, nodeType: Node = null, defaultNode: Node = null): AttributeNode {
    return nodeObject(new AttributeNode(name, nodeType, nodeObject(defaultNode)));
}

@:build(Node.registerNodeClass)
static function registerNodeClass() {
    Node.registerNodeClass('AttributeNode', AttributeNode);
}