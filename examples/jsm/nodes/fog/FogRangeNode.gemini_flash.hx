import FogNode from "./FogNode";
import MathNode from "../math/MathNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class FogRangeNode extends FogNode {

  public var nearNode:Node;
  public var farNode:Node;

  public function new(colorNode:Node, nearNode:Node, farNode:Node) {
    super(colorNode);
    this.isFogRangeNode = true;
    this.nearNode = nearNode;
    this.farNode = farNode;
  }

  public function setup(builder:ShaderNode.Builder):Dynamic {
    var viewZ = this.getViewZNode(builder);
    return MathNode.smoothstep(this.nearNode, this.farNode, viewZ);
  }

}

var rangeFog = ShaderNode.nodeProxy(FogRangeNode);

ShaderNode.addNodeElement("rangeFog", rangeFog);

Node.addNodeClass("FogRangeNode", FogRangeNode);