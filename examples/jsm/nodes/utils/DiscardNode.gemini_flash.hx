import CondNode from "../math/CondNode";
import ExpressionNode from "../code/ExpressionNode";
import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class DiscardNode extends CondNode {
  static discardExpression: ExpressionNode;

  public function new(condNode: CondNode) {
    if (DiscardNode.discardExpression == null) {
      DiscardNode.discardExpression = new ExpressionNode("discard");
    }
    super(condNode, DiscardNode.discardExpression);
  }
}

var inlineDiscard = ShaderNode.nodeProxy(DiscardNode);
var discard = function(condNode: CondNode) {
  return inlineDiscard(condNode).append();
};

Node.addNodeElement("discard", discard); // @TODO: Check... this cause a little confusing using in chaining

Node.addNodeClass("DiscardNode", DiscardNode);