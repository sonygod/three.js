package three.js.examples.jm.nodes.utils;

import three.js.core.Node;
import three.js.core.constants.VectorComponents;

class SplitNode extends Node {
    public var node:Node;
    public var components:String;
    public var isSplitNode:Bool = true;

    public function new(node:Node, components:String = 'x') {
        super();
        this.node = node;
        this.components = components;
    }

    public function getVectorLength():Int {
        var vectorLength:Int = components.length;
        for (c in components) {
            vectorLength = Math.max(VectorComponents.indexOf(c) + 1, vectorLength);
        }
        return vectorLength;
    }

    public function getComponentType(builder:Dynamic):Dynamic {
        return builder.getComponentType(node.getNodeType(builder));
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        return builder.getTypeFromLength(components.length, getComponentType(builder));
    }

    public function generate(builder:Dynamic, output:Dynamic):String {
        var node:Node = this.node;
        var nodeTypeLength:Int = builder.getTypeLength(node.getNodeType(builder));
        var snippet:String = null;

        if (nodeTypeLength > 1) {
            var type:Dynamic = null;
            var componentsLength:Int = getVectorLength();

            if (componentsLength >= nodeTypeLength) {
                type = builder.getTypeFromLength(getVectorLength(), getComponentType(builder));
            }

            var nodeSnippet:String = node.build(builder, type);
            if (components.length == nodeTypeLength && components == StringTools.substr(VectorComponents.join(""), 0, components.length)) {
                snippet = builder.format(nodeSnippet, type, output);
            } else {
                snippet = builder.format('${nodeSnippet}.${components}', getNodeType(builder), output);
            }
        } else {
            snippet = node.build(builder, output);
        }
        return snippet;
    }

    public override function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.components = components;
    }

    public override function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        components = data.components;
    }
}

// Add node class
Node.addNodeClass("SplitNode", SplitNode);