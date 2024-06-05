import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";
import BackSide from "three/src/constants/Constants";
import WebGLCoordinateSystem from "three/src/constants/Constants";

class FrontFacingNode extends Node {

  public var isFrontFacingNode:Bool = true;

  public function new() {
    super("bool");
  }

  override public function generate(builder:ShaderNode.Builder):String {
    if (builder.renderer.coordinateSystem == WebGLCoordinateSystem) {
      if (builder.material.side == BackSide) {
        return "false";
      }
    }
    return builder.getFrontFacing();
  }

}

export var frontFacing = ShaderNode.nodeImmutable(FrontFacingNode);
export var faceDirection = ShaderNode.float(frontFacing).mul(2.0).sub(1.0);

Node.addNodeClass("FrontFacingNode", FrontFacingNode);