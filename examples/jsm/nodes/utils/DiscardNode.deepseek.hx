import three.js.examples.jsm.nodes.math.CondNode;
import three.js.examples.jsm.nodes.code.ExpressionNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class DiscardNode extends CondNode {

    static var discardExpression:ExpressionNode;

    public function new(condNode:CondNode) {

        discardExpression = discardExpression ? discardExpression : ExpressionNode.expression('discard');

        super(condNode, discardExpression);

    }

}

static function inlineDiscard(condNode:CondNode):DiscardNode {
    return ShaderNode.nodeProxy(DiscardNode, condNode);
}

static function discard(condNode:CondNode):DiscardNode {
    return inlineDiscard(condNode).append();
}

ShaderNode.addNodeElement('discard', discard); // @TODO: Check... this cause a little confusing using in chaining

Node.addNodeClass('DiscardNode', DiscardNode);