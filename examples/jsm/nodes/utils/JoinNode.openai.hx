package three.js.examples.jsm.nodes.utils;

import three.js.core.Node;
import three.js.core.TempNode;

class JoinNode extends TempNode {
    public var nodes:Array<TempNode>;

    public function new(nodes:Array<TempNode> = [], nodeType:String = null) {
        super(nodeType);
        this.nodes = nodes;
    }

    public function getNodeType(builder:Builder):String {
        if (this.nodeType != null) {
            return builder.getVectorType(this.nodeType);
        }
        var len:Int = 0;
        for (node in nodes) {
            len += builder.getTypeLength(node.getNodeType(builder));
        }
        return builder.getTypeFromLength(len);
    }

    public function generate(builder:Builder, output:String):String {
        var type:String = getNodeType(builder);
        var nodes:Array<TempNode> = this.nodes;
        var primitiveType:String = builder.getComponentType(type);
        var snippetValues:Array<String> = [];
        for (node in nodes) {
            var inputSnippet:String = node.build(builder);
            var inputPrimitiveType:String = builder.getComponentType(node.getNodeType(builder));
            if (inputPrimitiveType != primitiveType) {
                inputSnippet = builder.format(inputSnippet, inputPrimitiveType, primitiveType);
            }
            snippetValues.push(inputSnippet);
        }
        var snippet:String = '${builder.getType(type)}(${snippetValues.join(', ')})';
        return builder.format(snippet, type, output);
    }
}

// Register the JoinNode class
three.js.core.addNodeClass('JoinNode', JoinNode);