package three.js.examples.jsm.nodes.core;

import three.js.examples.jsm.nodes.Node;

class ContextNode extends Node {
    public var isContextNode:Bool = true;
    public var node:Node;
    public var context:Dynamic;

    public function new(node:Node, ?context:Dynamic) {
        super();
        this.node = node;
        this.context = context == null ? {} : context;
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        return node.getNodeType(builder);
    }

    public function setup(builder:Dynamic):Node {
        var previousContext:Dynamic = builder.getContext();
        builder.setContext({ ...builder.context, ...context });
        var node:Node = this.node.build(builder);
        builder.setContext(previousContext);
        return node;
    }

    public function generate(builder:Dynamic, output:Dynamic):Dynamic {
        var previousContext:Dynamic = builder.getContext();
        builder.setContext({ ...builder.context, ...context });
        var snippet:Dynamic = this.node.build(builder, output);
        builder.setContext(previousContext);
        return snippet;
    }
}

class ContextNodeProxy {
    public static function nodeProxy(node:Node, context:Dynamic):ContextNode {
        return new ContextNode(node, context);
    }
}

class ContextNodeLabel {
    public static function label(node:Node, name:String):ContextNode {
        return ContextNodeProxy.nodeProxy(node, { label: name });
    }
}

// register node elements
Node.addElement('context', ContextNodeProxy.nodeProxy);
Node.addElement('label', ContextNodeLabel.label);

// register node class
Node.addNodeClass('ContextNode', ContextNode);