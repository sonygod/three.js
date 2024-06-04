import core.Node;
import core.TempNode;

class JoinNode extends TempNode {
  public var nodes:Array<TempNode>;

  public function new(nodes:Array<TempNode> = [], nodeType:String = null) {
    super(nodeType);
    this.nodes = nodes;
  }

  public function getNodeType(builder:Node.NodeBuilder):String {
    if (this.nodeType != null) {
      return builder.getVectorType(this.nodeType);
    }

    return builder.getTypeFromLength(this.nodes.reduce((count, cur) => count + builder.getTypeLength(cur.getNodeType(builder)), 0));
  }

  public function generate(builder:Node.NodeBuilder, output:String):String {
    var type:String = this.getNodeType(builder);
    var nodes:Array<TempNode> = this.nodes;
    var primitiveType:String = builder.getComponentType(type);
    var snippetValues:Array<String> = [];

    for (input in nodes) {
      var inputSnippet:String = input.build(builder);
      var inputPrimitiveType:String = builder.getComponentType(input.getNodeType(builder));

      if (inputPrimitiveType != primitiveType) {
        inputSnippet = builder.format(inputSnippet, inputPrimitiveType, primitiveType);
      }

      snippetValues.push(inputSnippet);
    }

    var snippet:String = "${builder.getType(type)}(${snippetValues.join(', ')})";
    return builder.format(snippet, type, output);
  }
}

Node.addNodeClass('JoinNode', JoinNode);