import Node from "./Node";
import ShaderNode from "../shadernode/ShaderNode";

class BypassNode extends Node {

  public isBypassNode:Bool = true;

  public outputNode:Node;
  public callNode:Node;

  public function new(returnNode:Node, callNode:Node) {
    super();
    this.outputNode = returnNode;
    this.callNode = callNode;
  }

  public function getNodeType(builder:ShaderNode.Builder):ShaderNode.NodeType {
    return this.outputNode.getNodeType(builder);
  }

  public function generate(builder:ShaderNode.Builder):String {
    var snippet = this.callNode.build(builder, "void");

    if (snippet != "") {
      builder.addLineFlowCode(snippet);
    }

    return this.outputNode.build(builder);
  }

}

var bypass = ShaderNode.nodeProxy(BypassNode);

ShaderNode.addNodeElement("bypass", bypass);
ShaderNode.addNodeClass("BypassNode", BypassNode);