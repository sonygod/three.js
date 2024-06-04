import TempNode from "../core/TempNode";
import PositionNode from "../accessors/PositionNode";
import ShaderNode from "../shadernode/ShaderNode";

class EquirectUVNode extends TempNode {
  public var dirNode:ShaderNode;

  public function new(dirNode:ShaderNode = PositionNode.positionWorldDirection) {
    super("vec2");
    this.dirNode = dirNode;
  }

  override public function setup():ShaderNode {
    var dir = this.dirNode;
    var u = dir.z.atan2(dir.x).mul(1 / (Math.PI * 2)).add(0.5);
    var v = dir.y.clamp(-1.0, 1.0).asin().mul(1 / Math.PI).add(0.5);
    return ShaderNode.vec2(u, v);
  }
}

var equirectUV = ShaderNode.nodeProxy(EquirectUVNode);

class EquirectUVNodeProxy extends ShaderNode {
  public function new() {
    super(new EquirectUVNode());
  }
}

EquirectUVNode.addNodeClass("EquirectUVNode", EquirectUVNode);