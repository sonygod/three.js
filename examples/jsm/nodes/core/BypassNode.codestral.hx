class Node {
  public var isBypassNode:Bool;
  public var outputNode:Node;
  public var callNode:Node;

  public function new(returnNode:Node, callNode:Node) {
    this.isBypassNode = true;
    this.outputNode = returnNode;
    this.callNode = callNode;
  }

  public function getNodeType(builder:Builder):Dynamic {
    return this.outputNode.getNodeType(builder);
  }

  public function generate(builder:Builder):Dynamic {
    var snippet = this.callNode.build(builder, 'void');

    if (snippet != '') {
      builder.addLineFlowCode(snippet);
    }

    return this.outputNode.build(builder);
  }
}

class BypassNode extends Node {
  public function new(returnNode:Node, callNode:Node) {
    super(returnNode, callNode);
  }
}

class Builder {
  public function addLineFlowCode(snippet:String):Void {}
}

class ShaderNode {
  public static function nodeProxy(nodeClass:Class<Node>):Node {
    return Type.createInstance(nodeClass, []);
  }

  public static function addNodeElement(name:String, node:Node):Void {}
}

class NodeManager {
  public static function addNodeClass(name:String, nodeClass:Class<Node>):Void {}
}

var bypass = ShaderNode.nodeProxy(BypassNode);
ShaderNode.addNodeElement('bypass', bypass);
NodeManager.addNodeClass('BypassNode', BypassNode);