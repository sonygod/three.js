package three.js.examples.jsm.nodes.utils;

import three.js.examples.jsm.math.CondNode;
import three.js.examples.jsm.code.ExpressionNode;
import three.js.examples.jsm.core.Node;
import three.js.examples.jsm.shadernode.ShaderNode;

class DiscardNode extends CondNode {

    static var discardExpression:ExpressionNode;

    public function new(condNode:CondNode) {
        if (discardExpression == null) {
            discardExpression = ExpressionNode.create('discard');
        }
        super(condNode, discardExpression);
    }
}

class DiscardNodeProxy {
    public static function nodeProxy(node:DiscardNode):DiscardNode {
        return node;
    }
}

class Main {
    public static function main() {
        // Register the node element
        ShaderNode.addNodeElement('discard', DiscardNodeProxy.inlineDiscard);

        // Register the node class
        Node.addNodeClass('DiscardNode', DiscardNode);

        // Create a shortcut function
        var discard = function(condNode:CondNode) {
            return DiscardNodeProxy.inlineDiscard(condNode).append();
        }
    }
}