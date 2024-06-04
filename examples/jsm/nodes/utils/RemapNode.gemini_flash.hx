import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class RemapNode extends Node {

  public var node:ShaderNode;
  public var inLowNode:ShaderNode;
  public var inHighNode:ShaderNode;
  public var outLowNode:ShaderNode;
  public var outHighNode:ShaderNode;
  public var doClamp:Bool = true;

  public function new(node:ShaderNode, inLowNode:ShaderNode, inHighNode:ShaderNode, outLowNode:ShaderNode = ShaderNode.float(0), outHighNode:ShaderNode = ShaderNode.float(1)) {
    super();
    this.node = node;
    this.inLowNode = inLowNode;
    this.inHighNode = inHighNode;
    this.outLowNode = outLowNode;
    this.outHighNode = outHighNode;
  }

  public function setup():ShaderNode {
    var t = node.sub(inLowNode).div(inHighNode.sub(inLowNode));

    if (doClamp) {
      t = t.clamp();
    }

    return t.mul(outHighNode.sub(outLowNode)).add(outLowNode);
  }

}

class RemapNodeProxy extends ShaderNode.NodeProxy {

  public function new(doClamp:Bool = false) {
    super(RemapNode, null, null, {doClamp:doClamp});
  }

}

var remap = new RemapNodeProxy(false);
var remapClamp = new RemapNodeProxy();

ShaderNode.addNodeElement("remap", remap);
ShaderNode.addNodeElement("remapClamp", remapClamp);

ShaderNode.addNodeClass("RemapNode", RemapNode);