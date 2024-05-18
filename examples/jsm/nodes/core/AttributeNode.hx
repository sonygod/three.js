Here is the converted Haxe code:
```
package three.js.examples.jsm.nodes.core;

import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.VaryingNode;

class AttributeNode extends Node {

    private var _attributeName:String;
    private var defaultNode:Node;

    public function new(attributeName:String, nodeType:Null<NodeType> = null, defaultNode:Null<Node> = null) {
        super(nodeType);
        this.defaultNode = defaultNode;
        this._attributeName = attributeName;
    }

    public function isGlobal():Bool {
        return true;
    }

    public function getHash(builder:Dynamic):String {
        return getAttributeName(builder);
    }

    public function getNodeType(builder:Dynamic):NodeType {
        var nodeType:NodeType = super.getNodeType(builder);
        if (nodeType == null) {
            var attributeName:String = getAttributeName(builder);
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

    public function getAttributeName(builder:Dynamic):String {
        return this._attributeName;
    }

    public function generate(builder:Dynamic):String {
        var attributeName:String = getAttributeName(builder);
        var nodeType:NodeType = getNodeType(builder);
        var geometryAttribute:Bool = builder.hasGeometryAttribute(attributeName);

        if (geometryAttribute) {
            var attribute:Dynamic = builder.geometry.getAttribute(attributeName);
            var attributeType:NodeType = builder.getTypeFromAttribute(attribute);
            var nodeAttribute:Dynamic = builder.getAttribute(attributeName, attributeType);

            if (builder.shaderStage == 'vertex') {
                return builder.format(nodeAttribute.name, attributeType, nodeType);
            } else {
                var nodeVarying:VaryingNode = VaryingNode.create(this);
                return nodeVarying.build(builder, nodeType);
            }
        } else {
            trace('AttributeNode: Vertex attribute "${attributeName}" not found on geometry.');
            if (defaultNode != null) {
                return defaultNode.build(builder, nodeType);
            } else {
                return builder.generateConst(nodeType);
            }
        }
    }
}

// export
extern class AttributeNode {
    public static function create(name:String, nodeType:Null<NodeType> = null, defaultNode:Null<Node> = null):AttributeNode {
        return new AttributeNode(name, nodeType, Node.object(defaultNode));
    }
}

// register node class
Node.addNodeClass('AttributeNode', AttributeNode);
```
Note that I've used the `extern` keyword to define the `AttributeNode` class, which is the equivalent of the JavaScript `export` keyword. I've also used the `Node.object` function to wrap the `defaultNode` parameter, which is equivalent to the JavaScript `nodeObject` function.

Also, I've assumed that the `NodeType` type is defined elsewhere in your Haxe project. If that's not the case, you'll need to define it or replace it with the appropriate type.