import TempNode from "../core/TempNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class PosterizeNode extends TempNode {
  public var sourceNode: Node;
  public var stepsNode: Node;

  public function new(sourceNode: Node, stepsNode: Node) {
    super();
    this.sourceNode = sourceNode;
    this.stepsNode = stepsNode;
  }

  override public function setup(): Node {
    return sourceNode.mul(stepsNode).floor().div(stepsNode);
  }
}

export var posterize: ShaderNode = ShaderNode.proxy(PosterizeNode);

ShaderNode.addNodeElement("posterize", posterize);
Node.addNodeClass("PosterizeNode", PosterizeNode);