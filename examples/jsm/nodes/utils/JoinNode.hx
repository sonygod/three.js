package three.js.examples.jsm.nodes.utils;

import three.js.core.Node;
import three.js.core.TempNode;

class JoinNode extends TempNode {
    public var nodes:Array<TempNode>;
    public var nodeType:Null<NodeType>;

    public function new(nodes:Array<TempNode> = [], nodeType:Null<NodeType> = null) {
        super(nodeType);
        this.nodes = nodes;
    }

    public function getNodeType(builder:Dynamic):NodeType {
        if (this.nodeType != null) {
            return builder.getVectorType(this.nodeType);
        }
        var length:Int = 0;
        for (node in nodes) {
            length += builder.getTypeLength(node.getNodeType(builder));
        }
        return builder.getTypeFromLength(length);
    }

    public function generate(builder:Dynamic, output:Dynamic):String {
        var type:NodeType = getNodeType(builder);
        var nodes:Array<TempNode> = this.nodes;
        var primitiveType:NodeType = builder.getComponentType(type);
        var snippetValues:Array<String> = [];
        for (node in nodes) {
            var inputSnippet:String = node.build(builder);
            var inputPrimitiveType:NodeType = builder.getComponentType(node.getNodeType(builder));
            if (inputPrimitiveType != primitiveType) {
                inputSnippet = builder.format(inputSnippet, inputPrimitiveType, primitiveType);
            }
            snippetValues.push(inputSnippet);
        }
        var snippet:String = '${builder.getType(type)}(${snippetValues.join(", ")})';
        return builder.format(snippet, type, output);
    }
}

// Register the node class
Node.addNodeClass('JoinNode', JoinNode);