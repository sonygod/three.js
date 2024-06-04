import TempNode from "../core/TempNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class PosterizeNode extends TempNode {
  public sourceNode: Node;
  public stepsNode: Node;

  public function new(sourceNode: Node, stepsNode: Node) {
    super();
    this.sourceNode = sourceNode;
    this.stepsNode = stepsNode;
  }

  override public function setup(): Node {
    return this.sourceNode.mul(this.stepsNode).floor().div(this.stepsNode);
  }
}

var posterize = ShaderNode.nodeProxy(PosterizeNode);

ShaderNode.addNodeElement("posterize", posterize);
Node.addNodeClass("PosterizeNode", PosterizeNode);