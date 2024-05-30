import CondNode from '../math/CondNode.hx';
import { expression } from '../code/ExpressionNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

var discardExpression:Dynamic;

class DiscardNode extends CondNode {

	public function new( condNode:Dynamic ) {

		if( discardExpression == null ) {

			discardExpression = expression( 'discard' );

		}

		super( condNode, discardExpression );

	}

}

@:autoBuild
class InlineDiscard {

	public static function inlineDiscard( condNode:Dynamic ) {

		return nodeProxy( DiscardNode, condNode );

	}

}

addNodeElement( 'discard', InlineDiscard.discard ); // @TODO: Check... this cause a little confusing using in chaining

addNodeClass( 'DiscardNode', DiscardNode );