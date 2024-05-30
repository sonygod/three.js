import TempNode from '../core/TempNode.hx';
import { sub, mul, div } from './OperatorNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeObject, nodeProxy, float, vec3, vec4 } from '../shadernode/ShaderNode.hx';

class MathNode extends TempNode {

	public var method:String;
	public var aNode:Dynamic;
	public var bNode:Dynamic;
	public var cNode:Dynamic;

	public function new( method:String, aNode:Dynamic, bNode:Dynamic = null, cNode:Dynamic = null ) {

		super();

		this.method = method;

		this.aNode = aNode;
		this.bNode = bNode;
		this.cNode = cNode;

	}

	public function getInputType( builder:Dynamic ) {

		var aType = this.aNode.getNodeType( builder );
		var bType = this.bNode ? this.bNode.getNodeType( builder ) : null;
		var cType = this.cNode ? this.cNode.getNodeType( builder ) : null;

		var aLen = builder.isMatrix( aType ) ? 0 : builder.getTypeLength( aType );
		var bLen = builder.isMatrix( bType ) ? 0 : builder.getTypeLength( bType );
		var cLen = builder.isMatrix( cType ) ? 0 : builder.getTypeLength( cType );

		if ( aLen > bLen && aLen > cLen ) {

			return aType;

		} else if ( bLen > cLen ) {

			return bType;

		} else if ( cLen > aLen ) {

			return cType;

		}

		return aType;

	}

	public function getNodeType( builder:Dynamic ) {

		var method = this.method;

		if ( method == MathNode.LENGTH || method == MathNode.DISTANCE || method == MathNode.DOT ) {

			return 'float';

		} else if ( method == MathNode.CROSS ) {

			return 'vec3';

		} else if ( method == MathNode.ALL ) {

			return 'bool';

		} else if ( method == MathNode.EQUALS ) {

			return builder.changeComponentType( this.aNode.getNodeType( builder ), 'bool' );

		} else if ( method == MathNode.MOD ) {

			return this.aNode.getNodeType( builder );

		} else {

			return this.getInputType( builder );

		}

	}

	public function generate( builder:Dynamic, output:Dynamic ) {

		var method = this.method;

		var type = this.getNodeType( builder );
		var inputType = this.getInputType( builder );

		var a = this.aNode;
		var b = this.bNode;
		var c = this.cNode;

		var isWebGL = builder.renderer.isWebGLRenderer == true;

		if ( method == MathNode.TRANSFORM_DIRECTION ) {

			// dir can be either a direction vector or a normal vector
			// upper-left 3x3 of matrix is assumed to be orthogonal

			var tA = a;
			var tB = b;

			if ( builder.isMatrix( tA.getNodeType( builder ) ) ) {

				tB = vec4( vec3( tB ), 0.0 );

			} else {

				tA = vec4( vec3( tA ), 0.0 );

			}

			var mulNode = mul( tA, tB ).xyz;

			return normalize( mulNode ).build( builder, output );

		} else if ( method == MathNode.NEGATE ) {

			return builder.format( '( - ' + a.build( builder, inputType ) + ' )', type, output );

		} else if ( method == MathNode.ONE_MINUS ) {

			return sub( 1.0, a ).build( builder, output );

		} else if ( method == MathNode.RECIPROCAL ) {

			return div( 1.0, a ).build( builder, output );

		} else if ( method == MathNode.DIFFERENCE ) {

			return abs( sub( a, b ) ).build( builder, output );

		} else {

			var params = [];

			if ( method == MathNode.CROSS || method == MathNode.MOD ) {

				params.push(
					a.build( builder, type ),
					b.build( builder, type )
				);

			} else if ( method == MathNode.STEP ) {

				params.push(
					a.build( builder, builder.getTypeLength( a.getNodeType( builder ) ) == 1 ? 'float' : inputType ),
					b.build( builder, inputType )
				);

			} else if ( ( isWebGL && ( method == MathNode.MIN || method == MathNode.MAX ) ) || method == MathNode.MOD ) {

				params.push(
					a.build( builder, inputType ),
					b.build( builder, builder.getTypeLength( b.getNodeType( builder ) ) == 1 ? 'float' : inputType )
				);

			} else if ( method == MathNode.REFRACT ) {

				params.push(
					a.build( builder, inputType ),
					b.build( builder, inputType ),
					c.build( builder, 'float' )
				);

			} else if ( method == MathNode.MIX ) {

				params.push(
					a.build( builder, inputType ),
					b.build( builder, inputType ),
					c.build( builder, builder.getTypeLength( c.getNodeType( builder ) ) == 1 ? 'float' : inputType )
				);

			} else {

				params.push( a.build( builder, inputType ) );
				if ( b != null ) params.push( b.build( builder, inputType ) );
				if ( c != null ) params.push( c.build( builder, inputType ) );

			}

			return builder.format( `${ builder.getMethod( method, type ) }( ${params.join( ', ' )} )`, type, output );

		}

	}

	public function serialize( data:Dynamic ) {

		super.serialize( data );

		data.method = this.method;

	}

	public function deserialize( data:Dynamic ) {

		super.deserialize( data );

		this.method = data.method;

	}

}

// 1 input

MathNode.ALL = 'all';
MathNode.ANY = 'any';
MathNode.EQUALS = 'equals';

MathNode.RADIANS = 'radians';
MathNode.DEGREES = 'degrees';
MathNode.EXP = 'exp';
MathNode.EXP2 = 'exp2';
MathNode.LOG = 'log';
MathNode.LOG2 = 'log2';
MathNode.SQRT = 'sqrt';
MathNode.INVERSE_SQRT = 'inversesqrt';
MathNode.FLOOR = 'floor';
MathNode.CEIL = 'ceil';
MathNode.NORMALIZE = 'normalize';
MathNode.FRACT = 'fract';
MathNode.SIN = 'sin';
MathNode.COS = 'cos';
MathNode.TAN = 'tan';
MathNode.ASIN = 'asin';
MathNode.ACOS = 'acos';
MathNode.ATAN = 'atan';
MathNode.ABS = 'abs';
MathNode.SIGN = 'sign';
MathNode.LENGTH = 'length';
MathNode.NEGATE = 'negate';
MathNode.ONE_MINUS = 'oneMinus';
MathNode.DFDX = 'dFdx';
MathNode.DFDY = 'dFdy';
MathNode.ROUND = 'round';
MathNode.RECIPROCAL = 'reciprocal';
MathNode.TRUNC = 'trunc';
MathNode.FWIDTH = 'fwidth';
MathNode.BITCAST = 'bitcast';

// 2 inputs

MathNode.ATAN2 = 'atan2';
MathNode.MIN = 'min';
MathNode.MAX = 'max';
MathNode.MOD = 'mod';
MathNode.STEP = 'step';
MathNode.REFLECT = 'reflect';
MathNode.DISTANCE = 'distance';
MathNode.DIFFERENCE = 'difference';
MathNode.DOT = 'dot';
MathNode.CROSS = 'cross';
MathNode.POW = 'pow';
MathNode.TRANSFORM_DIRECTION = 'transformDirection';

// 3 inputs

MathNode.MIX = 'mix';
MathNode.CLAMP = 'clamp';
MathNode.REFRACT = 'refract';
MathNode.SMOOTHSTEP = 'smoothstep';
MathNode.FACEFORWARD = 'faceforward';

export default MathNode;

export var EPSILON = float( 1e-6 );
export var INFINITY = float( 1e6 );
export var PI = float( Math.PI );
export var PI2 = float( Math.PI * 2 );

export var all = nodeProxy( MathNode, MathNode.ALL );
export var any = nodeProxy( MathNode, MathNode.ANY );
export var equals = nodeProxy( MathNode, MathNode.EQUALS );

export var radians = nodeProxy( MathNode, MathNode.RADIANS );
export var degrees = nodeProxy( MathNode, MathNode.DEGREES );
export var exp = nodeProxy( MathNode, MathNode.EXP );
export var exp2 = nodeProxy( MathNode, MathNode.EXP2 );
export var log = nodeProxy( MathNode, MathNode.LOG );
export var log2 = nodeProxy( MathNode, MathNode.LOG2 );
export var sqrt = nodeProxy( MathNode, MathNode.SQRT );
export var inverseSqrt = nodeProxy( MathNode, MathNode.INVERSE_SQRT );
export var floor = nodeProxy( MathNode, MathNode.FLOOR );
export var ceil = nodeProxy( MathNode, MathNode.CEIL );
export var normalize = nodeProxy( MathNode, MathNode.NORMALIZE );
export var fract = nodeProxy( MathNode, MathNode.FRACT );
export var sin = nodeProxy( MathNode, MathNode.SIN );
export var cos = nodeProxy( MathNode, MathNode.COS );
export var tan = nodeProxy( MathNode, MathNode.TAN );
export var asin = nodeProxy( MathNode, MathNode.ASIN );
export var acos = nodeProxy( MathNode, MathNode.ACOS );
export var atan = nodeProxy( MathNode, MathNode.ATAN );
export var abs = nodeProxy( MathNode, MathNode.ABS );
export var sign = nodeProxy( MathNode, MathNode.SIGN );
export var length = nodeProxy( MathNode, MathNode.LENGTH );
export var negate = nodeProxy( MathNode, MathNode.NEGATE );
export var oneMinus = nodeProxy( MathNode, MathNode.ONE_MINUS );
export var dFdx = nodeProxy( MathNode, MathNode.DFDX );
export var dFdy = nodeProxy( MathNode, MathNode.DFDY );
export var round = nodeProxy( MathNode, MathNode.ROUND );
export var reciprocal = nodeProxy( MathNode, MathNode.RECIPROCAL );
export var trunc = nodeProxy( MathNode, MathNode.TRUNC );
export var fwidth = nodeProxy( MathNode, MathNode.FWIDTH );
export var bitcast = nodeProxy( MathNode, MathNode.BITCAST );

export var atan2 = nodeProxy( MathNode, MathNode.ATAN2 );
export var min = nodeProxy( MathNode, MathNode.MIN );
export var max = nodeProxy( MathNode, MathNode.MAX );
export var mod = nodeProxy( MathNode, MathNode.MOD );
export var step = nodeProxy( MathNode, MathNode.STEP );
export var reflect = nodeProxy( MathNode, MathNode.REFLECT );
export var distance = nodeProxy( MathNode, MathNode.DISTANCE );
export var difference = nodeProxy( MathNode, MathNode.DIFFERENCE );
export var dot = nodeProxy( MathNode, MathNode.DOT );
export var cross = nodeProxy( MathNode, MathNode.CROSS );
export var pow = nodeProxy( MathNode, MathNode.POW );
export var pow2 = nodeProxy( MathNode, MathNode.POW, 2 );
export var pow3 = nodeProxy( MathNode, MathNode.POW, 3 );
export var pow4 = nodeProxy( MathNode, MathNode.POW, 4 );
export var transformDirection = nodeProxy( MathNode, MathNode.TRANSFORM_DIRECTION );

export var cbrt = ( a ) => mul( sign( a ), pow( abs( a ), 1.0 / 3.0 ) );
export var lengthSq = ( a ) => dot( a, a );
export var mix = nodeProxy( MathNode, MathNode.MIX );
export var clamp = ( value, low = 0, high = 1 ) => nodeObject( new MathNode( MathNode.CLAMP, nodeObject( value ), nodeObject( low ), nodeObject( high ) ) );
export var saturate = ( value ) => clamp( value );
export var refract = nodeProxy( MathNode, MathNode.REFRACT );
export var smoothstep = nodeProxy( MathNode, MathNode.SMOOTHSTEP );
export var faceForward = nodeProxy( MathNode, MathNode.FACEFORWARD );

export var mixElement = ( t, e1, e2 ) => mix( e1, e2, t );
export var smoothstepElement = ( x, low, high ) => smoothstep( low, high, x );

addNodeElement( 'all', all );
addNodeElement( 'any', any );
addNodeElement( 'equals', equals );

addNodeElement( 'radians', radians );
addNodeElement( 'degrees', degrees );
addNodeElement( 'exp', exp );
addNodeElement( 'exp2', exp2 );
addNodeElement( 'log', log );
addNodeElement( 'log2', log2 );
addNodeElement( 'sqrt', sqrt );
addNodeElement( 'inverseSqrt', inverseSqrt );
addNodeElement( 'floor', floor );
addNodeElement( 'ceil', ceil );
addNodeElement( 'normalize', normalize );
addNodeElement( 'fract', fract );
addNodeElement( 'sin', sin );
addNodeElement( 'cos', cos );
addNodeElement( 'tan', tan );
addNodeElement( 'asin', asin );
addNodeElement( 'acos', acos );
addNodeElement( 'atan', atan );
addNodeElement( 'abs', abs );
addNodeElement( 'sign', sign );
addNodeElement( 'length', length );
addNodeElement( 'lengthSq', lengthSq );
addNodeElement( 'negate', negate );
addNodeElement( 'oneMinus', oneMinus );
addNodeElement( 'dFdx', dFdx );
addNodeElement( 'dFdy', dFdy );
addNodeElement( 'round', round );
addNodeElement( 'reciprocal', reciprocal );
addNodeElement( 'trunc', trunc );
addNodeElement( 'fwidth', fwidth );
addNodeElement( 'atan2', atan2 );
addNodeElement( 'min', min );
addNodeElement( 'max', max );
addNodeElement( 'mod', mod );
addNodeElement( 'step', step );
addNodeElement( 'reflect', reflect );
addNodeElement( 'distance', distance );
addNodeElement( 'dot', dot );
addNodeElement( 'cross', cross );
addNodeElement( 'pow', pow );
addNodeElement( 'pow2', pow2 );
addNodeElement( 'pow3', pow3 );
addNodeElement( 'pow4', pow4 );
addNodeElement( 'transformDirection', transformDirection );
addNodeElement( 'mix', mixElement );
addNodeElement( 'clamp', clamp );
addNodeElement( 'refract', refract );
addNodeElement( 'smoothstep', smoothstepElement );
addNodeElement( 'faceForward', faceForward );
addNodeElement( 'difference', difference );
addNodeElement( 'saturate', saturate );
addNodeElement( 'cbrt', cbrt );

addNodeClass( 'MathNode', MathNode );