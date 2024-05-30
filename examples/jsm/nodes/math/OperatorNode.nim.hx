import TempNode from '../core/TempNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class OperatorNode extends TempNode {

	public var op:String;
	public var aNode:TempNode;
	public var bNode:TempNode;

	public function new( op:String, aNode:TempNode, bNode:TempNode, ...params:Array<Dynamic> ) {

		super();

		this.op = op;

		if ( params.length > 0 ) {

			var finalBNode = bNode;

			for ( i in 0...params.length ) {

				finalBNode = new OperatorNode( op, finalBNode, params[i] );

			}

			bNode = finalBNode;

		}

		this.aNode = aNode;
		this.bNode = bNode;

	}

	public function getNodeType( builder:ShaderBuilder, output:String ):String {

		var op = this.op;

		var aNode = this.aNode;
		var bNode = this.bNode;

		var typeA = aNode.getNodeType( builder );
		var typeB = (typeof bNode !== 'undefined') ? bNode.getNodeType( builder ) : null;

		if ( typeA == 'void' || typeB == 'void' ) {

			return 'void';

		} else if ( op == '%' ) {

			return typeA;

		} else if ( op == '~' || op == '&' || op == '|' || op == '^' || op == '>>' || op == '<<' ) {

			return builder.getIntegerType( typeA );

		} else if ( op == '!' || op == '==' || op == '&&' || op == '||' || op == '^^' ) {

			return 'bool';

		} else if ( op == '<' || op == '>' || op == '<=' || op == '>=' ) {

			var typeLength = (output != null) ? builder.getTypeLength( output ) : Math.max( builder.getTypeLength( typeA ), builder.getTypeLength( typeB ) );

			return typeLength > 1 ? `bvec${ typeLength }` : 'bool';

		} else {

			if ( typeA == 'float' && builder.isMatrix( typeB ) ) {

				return typeB;

			} else if ( builder.isMatrix( typeA ) && builder.isVector( typeB ) ) {

				// matrix x vector

				return builder.getVectorFromMatrix( typeA );

			} else if ( builder.isVector( typeA ) && builder.isMatrix( typeB ) ) {

				// vector x matrix

				return builder.getVectorFromMatrix( typeB );

			} else if ( builder.getTypeLength( typeB ) > builder.getTypeLength( typeA ) ) {

				// anytype x anytype: use the greater length vector

				return typeB;

			}

			return typeA;

		}

	}

	public function generate( builder:ShaderBuilder, output:String ):String {

		var op = this.op;

		var aNode = this.aNode;
		var bNode = this.bNode;

		var type = this.getNodeType( builder, output );

		var typeA = null;
		var typeB = null;

		if ( type != 'void' ) {

			typeA = aNode.getNodeType( builder );
			typeB = (typeof bNode !== 'undefined') ? bNode.getNodeType( builder ) : null;

			if ( op == '<' || op == '>' || op == '<=' || op == '>=' || op == '==' ) {

				if ( builder.isVector( typeA ) ) {

					typeB = typeA;

				} else {

					typeA = typeB = 'float';

				}

			} else if ( op == '>>' || op == '<<' ) {

				typeA = type;
				typeB = builder.changeComponentType( typeB, 'uint' );

			} else if ( builder.isMatrix( typeA ) && builder.isVector( typeB ) ) {

				// matrix x vector

				typeB = builder.getVectorFromMatrix( typeA );

			} else if ( builder.isVector( typeA ) && builder.isMatrix( typeB ) ) {

				// vector x matrix

				typeA = builder.getVectorFromMatrix( typeB );

			} else {

				// anytype x anytype

				typeA = typeB = type;

			}

		} else {

			typeA = typeB = type;

		}

		var a = aNode.build( builder, typeA );
		var b = (typeof bNode !== 'undefined') ? bNode.build( builder, typeB ) : null;

		var outputLength = builder.getTypeLength( output );
		var fnOpSnippet = builder.getFunctionOperator( op );

		if ( output != 'void' ) {

			if ( op == '<' && outputLength > 1 ) {

				return builder.format( `${ builder.getMethod( 'lessThan' ) }( ${ a }, ${ b } )`, type, output );

			} else if ( op == '<=' && outputLength > 1 ) {

				return builder.format( `${ builder.getMethod( 'lessThanEqual' ) }( ${ a }, ${ b } )`, type, output );

			} else if ( op == '>' && outputLength > 1 ) {

				return builder.format( `${ builder.getMethod( 'greaterThan' ) }( ${ a }, ${ b } )`, type, output );

			} else if ( op == '>=' && outputLength > 1 ) {

				return builder.format( `${ builder.getMethod( 'greaterThanEqual' ) }( ${ a }, ${ b } )`, type, output );

			} else if ( op == '!' || op == '~' ) {

				return builder.format( `(${op}${a})`, typeA, output );

			} else if ( fnOpSnippet ) {

				return builder.format( `${ fnOpSnippet }( ${ a }, ${ b } )`, type, output );

			} else {

				return builder.format( `( ${ a } ${ op } ${ b } )`, type, output );

			}

		} else if ( typeA != 'void' ) {

			if ( fnOpSnippet ) {

				return builder.format( `${ fnOpSnippet }( ${ a }, ${ b } )`, type, output );

			} else {

				return builder.format( `${ a } ${ op } ${ b }`, type, output );

			}

		}

	}

	public function serialize( data:Dynamic ):Dynamic {

		super.serialize( data );

		data.op = this.op;

	}

	public function deserialize( data:Dynamic ):Dynamic {

		super.deserialize( data );

		this.op = data.op;

	}

}

export default OperatorNode;

export var add = nodeProxy( OperatorNode, '+' );
export var sub = nodeProxy( OperatorNode, '-' );
export var mul = nodeProxy( OperatorNode, '*' );
export var div = nodeProxy( OperatorNode, '/' );
export var remainder = nodeProxy( OperatorNode, '%' );
export var equal = nodeProxy( OperatorNode, '==' );
export var notEqual = nodeProxy( OperatorNode, '!=' );
export var lessThan = nodeProxy( OperatorNode, '<' );
export var greaterThan = nodeProxy( OperatorNode, '>' );
export var lessThanEqual = nodeProxy( OperatorNode, '<=' );
export var greaterThanEqual = nodeProxy( OperatorNode, '>=' );
export var and = nodeProxy( OperatorNode, '&&' );
export var or = nodeProxy( OperatorNode, '||' );
export var not = nodeProxy( OperatorNode, '!' );
export var xor = nodeProxy( OperatorNode, '^^' );
export var bitAnd = nodeProxy( OperatorNode, '&' );
export var bitNot = nodeProxy( OperatorNode, '~' );
export var bitOr = nodeProxy( OperatorNode, '|' );
export var bitXor = nodeProxy( OperatorNode, '^' );
export var shiftLeft = nodeProxy( OperatorNode, '<<' );
export var shiftRight = nodeProxy( OperatorNode, '>>' );

addNodeElement( 'add', add );
addNodeElement( 'sub', sub );
addNodeElement( 'mul', mul );
addNodeElement( 'div', div );
addNodeElement( 'remainder', remainder );
addNodeElement( 'equal', equal );
addNodeElement( 'notEqual', notEqual );
addNodeElement( 'lessThan', lessThan );
addNodeElement( 'greaterThan', greaterThan );
addNodeElement( 'lessThanEqual', lessThanEqual );
addNodeElement( 'greaterThanEqual', greaterThanEqual );
addNodeElement( 'and', and );
addNodeElement( 'or', or );
addNodeElement( 'not', not );
addNodeElement( 'xor', xor );
addNodeElement( 'bitAnd', bitAnd );
addNodeElement( 'bitNot', bitNot );
addNodeElement( 'bitOr', bitOr );
addNodeElement( 'bitXor', bitXor );
addNodeElement( 'shiftLeft', shiftLeft );
addNodeElement( 'shiftRight', shiftRight );

addNodeClass( 'OperatorNode', OperatorNode );