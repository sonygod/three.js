import Node;
import NodeClass;
import ShaderNode;
import ShaderNodeElement;
import Builder;

class ContextNode extends Node {

    public var node: Node;
    public var context: Dynamic;

    public function new(node: Node, context: Dynamic = null) {
        super();

        this.isContextNode = true;

        this.node = node;
        this.context = context != null ? context : {};
    }

    public function getNodeType(builder: Builder): String {
        return this.node.getNodeType(builder);
    }

    public function setup(builder: Builder): String {
        var previousContext = builder.getContext();

        var newContext = {...builder.context, ...this.context};
        builder.setContext(newContext);

        var node = this.node.build(builder);

        builder.setContext(previousContext);

        return node;
    }

    public function generate(builder: Builder, output: String): String {
        var previousContext = builder.getContext();

        var newContext = {...builder.context, ...this.context};
        builder.setContext(newContext);

        var snippet = this.node.build(builder, output);

        builder.setContext(previousContext);

        return snippet;
    }
}

function nodeProxy(nodeClass: Class<ContextNode>): (node: Node, context: Dynamic) -> Node {
    return function(node: Node, context: Dynamic): Node {
        return new nodeClass(node, context);
    }
}

function label(node: Node, name: String): Node {
    return context(node, { label: name });
}

var context = nodeProxy(ContextNode);

ShaderNodeElement.addNodeElement("context", context);
ShaderNodeElement.addNodeElement("label", label);

NodeClass.addNodeClass("ContextNode", ContextNode);