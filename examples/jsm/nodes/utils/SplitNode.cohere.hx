import Node from "../core/Node.hx";
import { vectorComponents } from "../core/constants.hx";

class SplitNode extends Node {
    public node: Node;
    public components: String;
    public isSplitNode: Bool = true;

    public function new(node: Node, components: String = "x") {
        super();
        this.node = node;
        this.components = components;
    }

    public function getVectorLength(): Int {
        var vectorLength = this.components.length;
        for (c in this.components) {
            vectorLength = Math.max(vectorComponents.indexOf(c) + 1, vectorLength);
        }
        return vectorLength;
    }

    public function getComponentType(builder: Builder): Int {
        return builder.getComponentType(this.node.getNodeType(builder));
    }

    public function getNodeType(builder: Builder): Int {
        return builder.getTypeFromLength(this.components.length, this.getComponentType(builder));
    }

    public function generate(builder: Builder, output: Output): String {
        var node = this.node;
        var nodeTypeLength = builder.getTypeLength(node.getNodeType(builder));
        var snippet: String = null;
        if (nodeTypeLength > 1) {
            var type: Int = null;
            var componentsLength = this.getVectorLength();
            if (componentsLength >= nodeTypeLength) {
                type = builder.getTypeFromLength(this.getVectorLength(), this.getComponentType(builder));
            }
            var nodeSnippet = node.build(builder, type);
            if (this.components.length == nodeTypeLength && this.components == vectorComponents.slice(0, this.components.length).join("")) {
                snippet = builder.format(nodeSnippet, type, output);
            } else {
                snippet = builder.format("$nodeSnippet.$components", this.getNodeType(builder), output);
            }
        } else {
            snippet = node.build(builder, output);
        }
        return snippet;
    }

    public override function serialize(data: Dynamic) {
        super.serialize(data);
        data.components = this.components;
    }

    public override function deserialize(data: Dynamic) {
        super.deserialize(data);
        this.components = data.components;
    }
}

class Builder {
    public function getComponentType(nodeType: Int): Int {
        // TODO: Implement this function
        return 0;
    }

    public function getTypeFromLength(length: Int, componentType: Int): Int {
        // TODO: Implement this function
        return 0;
    }

    public function getTypeLength(type: Int): Int {
        // TODO: Implement this function
        return 0;
    }

    public function format(snippet: String, type: Int, output: Output): String {
        // TODO: Implement this function
        return "";
    }
}

class Output {
    // TODO: Define this class
}