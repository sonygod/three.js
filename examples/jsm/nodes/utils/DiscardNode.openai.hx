package three.js.examples.jsm.nodes.utils;

import three.js.math.CondsNode;
import three.js.code.ExpressionNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class DiscardNode extends CondNode {
    static var discardExpression: ExpressionNode;

    public function new(condNode: CondNode) {
        if (discardExpression == null) {
            discardExpression = ExpressionNode.fromString('discard');
        }
        super(condNode, discardExpression);
    }
}

@:keep
@:expose
class DiscardNodeProxy extends ShaderNode {
    public function new(condNode: CondNode) {
        super(new DiscardNode(condNode));
    }
}

// exports
inlineDiscard = DiscardNodeProxy;
discard = function(condNode: CondNode) return inlineDiscard(condNode).append();
Node.addElement('discard', discard);
Node.addClass('DiscardNode', DiscardNode);