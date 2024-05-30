import CondNode from '../math/CondNode.js';
import { expression } from '../code/ExpressionNode.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';

var discardExpression;

class DiscardNode extends CondNode {

	public function new(condNode:Dynamic) {

		discardExpression = discardExpression ?? expression('discard');

		super(condNode, discardExpression);

	}

}

export default DiscardNode;

export var inlineDiscard = nodeProxy(DiscardNode);
export var discard = function(condNode:Dynamic) return inlineDiscard(condNode).append();

addNodeElement('discard', discard); // @TODO: Check... this cause a little confusing using in chaining

addNodeClass('DiscardNode', DiscardNode);