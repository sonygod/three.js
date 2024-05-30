import three.js.examples.jsm.nodes.core.Node;

class ArrayElementNode extends Node {

    public function new(node:Node, indexNode:Node) {
        super();
        this.node = node;
        this.indexNode = indexNode;
        this.isArrayElementNode = true;
    }

    public function getNodeType(builder:Dynamic):String {
        return this.node.getNodeType(builder);
    }

    public function generate(builder:Dynamic):String {
        var nodeSnippet = this.node.build(builder);
        var indexSnippet = this.indexNode.build(builder, 'uint');
        return nodeSnippet + '[' + indexSnippet + ']';
    }

}

addNodeClass('ArrayElementNode', ArrayElementNode);