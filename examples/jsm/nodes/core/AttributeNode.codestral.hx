import Node;
import addNodeClass;
import VaryingNode.varying;
import ShaderNode.nodeObject;

class AttributeNode extends Node {

    public var defaultNode: Dynamic;
    private var _attributeName: String;

    public function new(attributeName: String, nodeType: String = null, defaultNode: Dynamic = null) {
        super(nodeType);
        this.defaultNode = defaultNode;
        this._attributeName = attributeName;
    }

    @:override
    public function isGlobal(): Bool {
        return true;
    }

    @:override
    public function getHash(builder: Dynamic): String {
        return this.getAttributeName(builder);
    }

    @:override
    public function getNodeType(builder: Dynamic): String {
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

    public function setAttributeName(attributeName: String): AttributeNode {
        this._attributeName = attributeName;
        return this;
    }

    public function getAttributeName(/*builder*/): String {
        return this._attributeName;
    }

    @:override
    public function generate(builder: Dynamic): String {
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

            if (this.defaultNode != null) {
                return this.defaultNode.build(builder, nodeType);
            } else {
                return builder.generateConst(nodeType);
            }
        }
    }
}

var attribute = function(name: String, nodeType: String, defaultNode: Dynamic): Dynamic {
    return nodeObject(new AttributeNode(name, nodeType, nodeObject(defaultNode)));
}

addNodeClass('AttributeNode', AttributeNode);