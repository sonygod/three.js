import js.Node;
import js.TempNode;

class JoinNode extends TempNode {

    private var nodes: Array<Node> = [];
    private var nodeType: Int = null;

    public function new(nodes:Array<Node> = [], nodeType:Int = null) {
        super(nodeType);
        this.nodes = nodes;
    }

    public function getNodeType(builder:Builder):Int {
        if (this.nodeType !== null) {
            return builder.getVectorType(this.nodeType);
        }

        var count:Int = 0;
        for (node in this.nodes) {
            count += builder.getTypeLength(node.getNodeType(builder));
        }

        return builder.getTypeFromLength(count);
    }

    public function generate(builder:Builder, output:Int):String {
        var type:Int = this.getNodeType(builder);
        var primitiveType:Int = builder.getComponentType(type);
        var snippetValues:Array<String> = [];

        for (input in this.nodes) {
            var inputSnippet:String = input.build(builder);
            var inputPrimitiveType:Int = builder.getComponentType(input.getNodeType(builder));

            if (inputPrimitiveType !== primitiveType) {
                inputSnippet = builder.format(inputSnippet, inputPrimitiveType, primitiveType);
            }

            snippetValues.push(inputSnippet);
        }

        var snippet:String = builder.getType(type) + "(" + snippetValues.join(", ") + ")";
        return builder.format(snippet, type, output);
    }
}

addNodeClass("JoinNode", JoinNode);