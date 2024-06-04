import Node from "../core/Node";
import PositionNode from "../accessors/PositionNode";
import ShaderNode from "../shadernode/ShaderNode";

class FogNode extends Node {

  public var isFogNode:Bool = true;
  public var colorNode:Node;
  public var factorNode:Node;

  public function new(colorNode:Node, factorNode:Node) {
    super("float");
    this.colorNode = colorNode;
    this.factorNode = factorNode;
  }

  public function getViewZNode(builder:ShaderNode):Node {
    var viewZ:Node = builder.context.getViewZ(this);
    if (viewZ == null) {
      viewZ = PositionNode.z.negate();
    }
    return viewZ;
  }

  public function setup():Node {
    return this.factorNode;
  }

}

class Fog {

  public static function nodeProxy(fogNode:FogNode):Node {
    return fogNode;
  }

}

ShaderNode.addNodeElement("fog", Fog.nodeProxy);
ShaderNode.addNodeClass("FogNode", FogNode);

export { FogNode };