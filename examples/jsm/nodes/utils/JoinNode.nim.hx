import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.TempNode;

class JoinNode extends TempNode {

  public var nodes:Array<Dynamic>;

  public function new(nodes:Array<Dynamic>, nodeType:Null<Dynamic>) {
    super(nodeType);
    this.nodes = nodes;
  }

  public function getNodeType(builder:Dynamic):Dynamic {
    if (this.nodeType != null) {
      return builder.getVectorType(this.nodeType);
    }
    return builder.getTypeFromLength(this.nodes.reduce(function(count:Dynamic, cur:Dynamic) {
      return count + builder.getTypeLength(cur.getNodeType(builder));
    }, 0));
  }

  public function generate(builder:Dynamic, output:Dynamic):Dynamic {
    var type:Dynamic = this.getNodeType(builder);
    var nodes:Array<Dynamic> = this.nodes;

    var primitiveType:Dynamic = builder.getComponentType(type);

    var snippetValues:Array<Dynamic> = [];

    for (input in nodes) {
      var inputSnippet:Dynamic = input.build(builder);

      var inputPrimitiveType:Dynamic = builder.getComponentType(input.getNodeType(builder));

      if (inputPrimitiveType != primitiveType) {
        inputSnippet = builder.format(inputSnippet, inputPrimitiveType, primitiveType);
      }

      snippetValues.push(inputSnippet);
    }

    var snippet:String = "${builder.getType(type)}(${snippetValues.join(', ')} )";

    return builder.format(snippet, type, output);
  }
}

Node.addNodeClass('JoinNode', JoinNode);