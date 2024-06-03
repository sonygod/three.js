import CondNode from '../math/CondNode.hx';
import ExpressionNode from '../code/ExpressionNode.hx';
import Node from '../core/Node.hx';
import ShaderNode from '../shadernode/ShaderNode.hx';

var discardExpression:ExpressionNode;

class DiscardNode extends CondNode {

    public function new(condNode:CondNode) {
        if (discardExpression == null) {
            discardExpression = ExpressionNode.expression('discard');
        }

        super(condNode, discardExpression);
    }

}

export default DiscardNode;

export function inlineDiscard(condNode:CondNode):ShaderNode {
    return ShaderNode.nodeProxy(DiscardNode, condNode);
}

export function discard(condNode:CondNode):ShaderNode {
    return inlineDiscard(condNode).append();
}

ShaderNode.addNodeElement('discard', discard);

Node.addNodeClass('DiscardNode', Type.getClass<DiscardNode>());