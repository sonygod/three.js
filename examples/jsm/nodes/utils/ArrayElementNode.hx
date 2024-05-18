package three.js.examples.jsm.nodes.utils;

import three.js.core.Node;

class ArrayElementNode extends Node {
    public var node:Node;
    public var indexNode:Node;
    public var isArrayElementNode:Bool = true;

    public function new(node:Node, indexNode:Node) {
        super();
        this.node = node;
        this.indexNode = indexNode;
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        return node.getNodeType(builder);
    }

    public function generate(builder:Dynamic):String {
        var nodeSnippet:String = node.build(builder);
        var indexSnippet:String = indexNode.build(builder, 'uint');
        return '$nodeSnippet[ $indexSnippet ]';
    }
}

registerClass('ArrayElementNode', ArrayElementNode);