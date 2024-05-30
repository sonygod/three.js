import Node, { addNodeClass } from '../core/Node.hx';
import ArrayElementNode from '../utils/ArrayElementNode.hx';
import ConvertNode from '../utils/ConvertNode.hx';
import JoinNode from '../utils/JoinNode.hx';
import SplitNode from '../utils/SplitNode.hx';
import SetNode from '../utils/SetNode.hx';
import ConstNode from '../core/ConstNode.hx';
import { getValueFromType, getValueType } from '../core/NodeUtils.hx';

//

var currentStack = null;

var NodeElements = new Map<String, Dynamic>(); // @TODO: Currently only a few nodes are added, probably also add others

export function addNodeElement( name:String, nodeElement:Dynamic ) {

	if ( NodeElements.has( name ) ) {

		trace.warn( `Redefinition of node element ${ name }` );
		return;

	}

	if ( Std.is( nodeElement, Function ) === false ) throw new Error( `Node element ${ name } is not a function` );

	NodeElements.set( name, nodeElement );

}

var parseSwizzle = ( props:String ) => props.replace( /r|s/g, 'x' ).replace( /g|t/g, 'y' ).replace( /b|p/g, 'z' ).replace( /a|q/g, 'w' );

var shaderNodeHandler = {

	setup: function( NodeClosure:Function, params:Array<Dynamic> ) {

		var inputs = params.shift();

		return NodeClosure( nodeObjects( inputs ), ...params );

	},

	get: function( node:Dynamic, prop:String, nodeObj:Dynamic ) {

		if ( Std.is( prop, String ) && Reflect.field( node, prop ) === null ) {

			if ( node.isStackNode !== true && prop === 'assign' ) {

				return function( ...params:Array<Dynamic> ) {

					currentStack.assign( nodeObj, ...params );

					return nodeObj;

				};

			} else if ( NodeElements.has( prop ) ) {

				var nodeElement = NodeElements.get( prop );

				return node.isStackNode ? function( ...params:Array<Dynamic> ) { nodeObj.add( nodeElement( ...params ) ); } : function( ...params:Array<Dynamic> ) { nodeElement( nodeObj, ...params ); };

			} else if ( prop === 'self' ) {

				return node;

			} else if ( prop.endsWith( 'Assign' ) && NodeElements.has( prop.slice( 0, prop.length - 'Assign'.length ) ) ) {

				var nodeElement = NodeElements.get( prop.slice( 0, prop.length - 'Assign'.length ) );

				return node.isStackNode ? function( ...params:Array<Dynamic> ) { nodeObj.assign( params[ 0 ], nodeElement( ...params ) ); } : function( ...params:Array<Dynamic> ) { nodeObj.assign( nodeElement( nodeObj, ...params ) ); };

			} else if ( /^[xyzwrgbastpq]{1,4}$/.test( prop ) === true ) {

				// accessing properties ( swizzle )

				prop = parseSwizzle( prop );

				return nodeObject( new SplitNode( nodeObj, prop ) );

			} else if ( /^set[XYZWRGBASTPQ]{1,4}$/.test( prop ) === true ) {

				// set properties ( swizzle )

				prop = parseSwizzle( prop.slice( 3 ).toLowerCase() );

				// sort to xyzw sequence

				prop = prop.split( '' ).sort().join( '' );

				return function( value:Dynamic ) { return nodeObject( new SetNode( node, prop, value ) ); };

			} else if ( prop === 'width' || prop === 'height' || prop === 'depth' ) {

				// accessing property

				if ( prop === 'width' ) prop = 'x';
				else if ( prop === 'height' ) prop = 'y';
				else if ( prop === 'depth' ) prop = 'z';

				return nodeObject( new SplitNode( node, prop ) );

			} else if ( /^\d+$/.test( prop ) === true ) {

				// accessing array

				return nodeObject( new ArrayElementNode( nodeObj, new ConstNode( Std.parseInt( prop ), 'uint' ) ) );

			}

		}

		return Reflect.field( node, prop );

	},

	set: function( node:Dynamic, prop:String, value:Dynamic, nodeObj:Dynamic ) {

		if ( Std.is( prop, String ) && Reflect.field( node, prop ) === null ) {

			// setting properties

			if ( /^[xyzwrgbastpq]{1,4}$/.test( prop ) === true || prop === 'width' || prop === 'height' || prop === 'depth' || /^\d+$/.test( prop ) === true ) {

				nodeObj[ prop ].assign( value );

				return true;

			}

		}

		return Reflect.setField( node, prop, value );

	}

};

var nodeObjectsCacheMap = new WeakMap<Dynamic, Dynamic>();
var nodeBuilderFunctionsCacheMap = new WeakMap<Function, Dynamic>();

var ShaderNodeObject = function( obj:Dynamic, altType:String ) {

	var type = getValueType( obj );

	if ( type === 'node' ) {

		var nodeObject = nodeObjectsCacheMap.get( obj );

		if ( nodeObject === null ) {

			nodeObject = new Proxy( obj, shaderNodeHandler );

			nodeObjectsCacheMap.set( obj, nodeObject );
			nodeObjectsCacheMap.set( nodeObject, nodeObject );

		}

		return nodeObject;

	} else if ( ( altType === null && ( type === 'float' || type === 'boolean' ) ) || ( type && type !== 'shader' && type !== 'string' ) ) {

		return nodeObject( getConstNode( obj, altType ) );

	} else if ( type === 'shader' ) {

		return tslFn( obj );

	}

	return obj;

};

var ShaderNodeObjects = function( objects:Dynamic, altType:String ) {

	for ( var name in objects ) {

		objects[ name ] = nodeObject( objects[ name ], altType );

	}

	return objects;

};

var ShaderNodeArray = function( array:Array<Dynamic>, altType:String ) {

	var len = array.length;

	for ( var i = 0; i < len; i ++ ) {

		array[ i ] = nodeObject( array[ i ], altType );

	}

	return array;

};

var ShaderNodeProxy = function( NodeClass:Function, scope:Dynamic, factor:Dynamic, settings:Dynamic ) {

	var assignNode = function( node:Dynamic ) { return nodeObject( settings !== null ? Std.object( node ).setAll( settings ) : node ); };

	if ( scope === null ) {

		return function( ...params:Array<Dynamic> ) {

			return assignNode( new NodeClass( ...nodeArray( params ) ) );

		};

	} else if ( factor !== null ) {

		factor = nodeObject( factor );

		return function( ...params:Array<Dynamic> ) {

			return assignNode( new NodeClass( scope, ...nodeArray( params ), factor ) );

		};

	} else {

		return function( ...params:Array<Dynamic> ) {

			return assignNode( new NodeClass( scope, ...nodeArray( params ) ) );

		};

	}

};

var ShaderNodeImmutable = function( NodeClass:Function, ...params:Array<Dynamic> ) {

	return nodeObject( new NodeClass( ...nodeArray( params ) ) );

};

class ShaderCallNodeInternal extends Node {

	constructor( shaderNode:Dynamic, inputNodes:Dynamic ) {

		super();

		this.shaderNode = shaderNode;
		this.inputNodes = inputNodes;

	}

	getNodeType( builder:Dynamic ) {

		var properties = builder.getNodeProperties( this );

		if ( properties.outputNode === null ) {

			properties.outputNode = this.setupOutput( builder );

		}

		return properties.outputNode.getNodeType( builder );

	}

	call( builder:Dynamic ) {

		var { shaderNode, inputNodes } = this;

		if ( shaderNode.layout ) {

			var functionNodesCacheMap = nodeBuilderFunctionsCacheMap.get( builder.constructor );

			if ( functionNodesCacheMap === null ) {

				functionNodesCacheMap = new WeakMap<Dynamic, Dynamic>();

				nodeBuilderFunctionsCacheMap.set( builder.constructor, functionNodesCacheMap );

			}

			var functionNode = functionNodesCacheMap.get( shaderNode );

			if ( functionNode === null ) {

				functionNode = nodeObject( builder.buildFunctionNode( shaderNode ) );

				functionNodesCacheMap.set( shaderNode, functionNode );

			}

			if ( builder.currentFunctionNode !== null ) {

				builder.currentFunctionNode.includes.push( functionNode );

			}

			return nodeObject( functionNode.call( inputNodes ) );

		}

		var jsFunc = shaderNode.jsFunc;
		var outputNode = inputNodes !== null ? jsFunc( inputNodes, builder.stack, builder ) : jsFunc( builder.stack, builder );

		return nodeObject( outputNode );

	}

	setup( builder:Dynamic ) {

		var { outputNode } = builder.getNodeProperties( this );

		return outputNode || this.setupOutput( builder );

	}

	setupOutput( builder:Dynamic ) {

		builder.addStack();

		builder.stack.outputNode = this.call( builder );

		return builder.removeStack();

	}

	generate( builder:Dynamic, output:Dynamic ) {

		var { outputNode } = builder.getNodeProperties( this );

		if ( outputNode === null ) {

			// TSL: It's recommended to use `tslFn` in setup() pass.

			return this.call( builder ).build( builder, output );

		}

		return super.generate( builder, output );

	}

}

class ShaderNodeInternal extends Node {

	constructor( jsFunc:Function ) {

		super();

		this.jsFunc = jsFunc;
		this.layout = null;

	}

	get isArrayInput() {

		return /^\((\s+)?\[/.test( this.jsFunc.toString() );

	}

	setLayout( layout:Dynamic ) {

		this.layout = layout;

		return this;

	}

	call( inputs:Dynamic ) {

		nodeObjects( inputs );

		return nodeObject( new ShaderCallNodeInternal( this, inputs ) );

	}

	setup() {

		return this.call();

	}

}

var bools = [ false, true ];
var uints = [ 0, 1, 2, 3 ];
var ints = [ - 1, - 2 ];
var floats = [ 0.5, 1.5, 1 / 3, 1e-6, 1e6, Math.PI, Math.PI * 2, 1 / Math.PI, 2 / Math.PI, 1 / ( Math.PI * 2 ), Math.PI / 2 ];

var boolsCacheMap = new Map<Bool, ConstNode>();
for ( var bool of bools ) boolsCacheMap.set( bool, new ConstNode( bool ) );

var uintsCacheMap = new Map<Int, ConstNode>();
for ( var uint of uints ) uintsCacheMap.set( uint, new ConstNode( uint, 'uint' ) );

var intsCacheMap = new Map<Int, ConstNode>( [ ...uintsCacheMap ].map( el => new ConstNode( el.value, 'int' ) ) );
for ( var int of ints ) intsCacheMap.set( int, new ConstNode( int, 'int' ) );

var floatsCacheMap = new Map<Float, ConstNode>( [ ...intsCacheMap ].map( el => new ConstNode( el.value ) ) );
for ( var float of floats ) floatsCacheMap.set( float, new ConstNode( float ) );
for ( var float of floats ) floatsCacheMap.set( - float, new ConstNode( - float ) );

var cacheMaps = { bool: boolsCacheMap, uint: uintsCacheMap, ints: intsCacheMap, float: floatsCacheMap };

var constNodesCacheMap = new Map<Dynamic, ConstNode>( [ ...boolsCacheMap, ...floatsCacheMap ] );

var getConstNode = ( value:Dynamic, type:String ) => {

	if ( constNodesCacheMap.has( value ) ) {

		return constNodesCacheMap.get( value );

	} else if ( value.isNode === true ) {

		return value;

	} else {

		return new ConstNode( value, type );

	}

};

var safeGetNodeType = ( node:Dynamic ) => {

	try {

		return node.getNodeType();

	} catch ( _ ) {

		return null;

	}

};

var ConvertType = function( type:String, cacheMap:Map<Dynamic, ConstNode> ) {

	return function( ...params:Array<Dynamic> ) {

		if ( params.length === 0 || ( ! [ 'bool', 'float', 'int', 'uint' ].includes( type ) && params.every( param => typeof param !== 'object' ) ) ) {

			params = [ getValueFromType( type, ...params ) ];

		}

		if ( params.length === 1 && cacheMap !== null && cacheMap.has( params[ 0 ] ) ) {

			return nodeObject( cacheMap.get( params[ 0 ] ) );

		}

		if ( params.length === 1 ) {

			var node = getConstNode( params[ 0 ], type );
			if ( safeGetNodeType( node ) === type ) return nodeObject( node );
			return nodeObject( new ConvertNode( nodeObject( node ), type ) );

		}

		var nodes = params.map( param => getConstNode( param ) );
		return nodeObject( new JoinNode( nodes, type ) );

	};

};

// exports

export var defined = ( value:Dynamic ) => value && value.value;

// utils

export var getConstNodeType = ( value:Dynamic ) => ( value !== null && value !== undefined ) ? ( value.nodeType || value.convertTo || ( typeof value === 'string' ? value : null ) ) : null;

// shader node base

export function ShaderNode( jsFunc:Function ) {

	return new Proxy( new ShaderNodeInternal( jsFunc ), shaderNodeHandler );

}

export var nodeObject = ( val:Dynamic, altType:String ) => /* new */ ShaderNodeObject( val, altType );
export var nodeObjects = ( val:Dynamic, altType:String ) => new ShaderNodeObjects( val, altType );
export var nodeArray = ( val:Dynamic, altType:String ) => new ShaderNodeArray( val, altType );
export var nodeProxy = ( ...params:Array<Dynamic> ) => new ShaderNodeProxy( ...params );
export var nodeImmutable = ( ...params:Array<Dynamic> ) => new ShaderNodeImmutable( ...params );

export var tslFn = ( jsFunc:Function ) => {

	var shaderNode = new ShaderNode( jsFunc );

	var fn = function( ...params:Array<Dynamic> ) {

		var inputs;

		nodeObjects( params );

		if ( params[ 0 ] && params[ 0 ].isNode ) {

			inputs = [ ...params ];

		} else {

			inputs = params[ 0 ];

		}

		return shaderNode.call( inputs );

	};

	fn.shaderNode = shaderNode;
	fn.setLayout = ( layout:Dynamic ) => {

		shaderNode.setLayout( layout );

		return fn;

	};

	return fn;

};

addNodeClass( 'ShaderNode', ShaderNode );

//

export var setCurrentStack = ( stack:Dynamic ) => {

	if ( currentStack === stack ) {

		//throw new Error( 'Stack already defined.' );

	}

	currentStack = stack;

};

export var getCurrentStack = () => currentStack;

export var If = ( ...params:Array<Dynamic> ) => currentStack.if( ...params );

export function append( node:Dynamic ) {

	if ( currentStack ) currentStack.add( node );

	return node;

}

addNodeElement( 'append', append );

// types
// @TODO: Maybe export from ConstNode.js?

export var color = new ConvertType( 'color' );

export var float = new ConvertType( 'float', cacheMaps.float );
export var int = new ConvertType( 'int', cacheMaps.ints );
export var uint = new ConvertType( 'uint', cacheMaps.uint );
export var bool = new ConvertType( 'bool', cacheMaps.bool );

export var vec2 = new ConvertType( 'vec2' );
export var ivec2 = new ConvertType( 'ivec2' );
export var uvec2 = new ConvertType( 'uvec2' );
export var bvec2 = new ConvertType( 'bvec2' );

export var vec3 = new ConvertType( 'vec3' );
export var ivec3 = new ConvertType( 'ivec3' );
export var uvec3 = new ConvertType( 'uvec3' );
export var bvec3 = new ConvertType( 'bvec3' );

export var vec4 = new ConvertType( 'vec4' );
export var ivec4 = new ConvertType( 'ivec4' );
export var uvec4 = new ConvertType( 'uvec4' );
export var bvec4 = new ConvertType( 'bvec4' );

export var mat2 = new ConvertType( 'mat2' );
export var imat2 = new ConvertType( 'imat2' );
export var umat2 = new ConvertType( 'umat2' );
export var bmat2 = new ConvertType( 'bmat2' );

export var mat3 = new ConvertType( 'mat3' );
export var imat3 = new ConvertType( 'imat3' );
export var umat3 = new ConvertType( 'umat3' );
export var bmat3 = new ConvertType( 'bmat3' );

export var mat4 = new ConvertType( 'mat4' );
export var imat4 = new ConvertType( 'imat4' );
export var umat4 = new ConvertType( 'umat4' );
export var bmat4 = new ConvertType( 'bmat4' );

export var string = ( value:String = '' ) => nodeObject( new ConstNode( value, 'string' ) );
export var arrayBuffer = ( value:Dynamic ) => nodeObject( new ConstNode( value, 'ArrayBuffer' ) );

addNodeElement( 'toColor', color );
addNodeElement( 'toFloat', float );
addNodeElement( 'toInt', int );
addNodeElement( 'toUint', uint );
addNodeElement( 'toBool', bool );
addNodeElement( 'toVec2', vec2 );
addNodeElement( 'toIvec2', ivec2 );
addNodeElement( 'toUvec2', uvec2 );
addNodeElement( 'toBvec2', bvec2 );
addNodeElement( 'toVec3', vec3 );
addNodeElement( 'toIvec3', ivec3 );
addNodeElement( 'toUvec3', uvec3 );
addNodeElement( 'toBvec3', bvec3 );
addNodeElement( 'toVec4', vec4 );
addNodeElement( 'toIvec4', ivec4 );
addNodeElement( 'toUvec4', uvec4 );
addNodeElement( 'toBvec4', bvec4 );
addNodeElement( 'toMat2', mat2 );
addNodeElement( 'toImat2', imat2 );
addNodeElement( 'toUmat2', umat2 );
addNodeElement( 'toBmat2', bmat2 );
addNodeElement( 'toMat3', mat3 );
addNodeElement( 'toImat3', imat3 );
addNodeElement( 'toUmat3', umat3 );
addNodeElement( 'toBmat3', bmat3 );
addNodeElement( 'toMat4', mat4 );
addNodeElement( 'toImat4', imat4 );
addNodeElement( 'toUmat4', umat4 );
addNodeElement( 'toBmat4', bmat4 );

// basic nodes
// HACK - we cannot export them from the corresponding files because of the cyclic dependency
export var element = nodeProxy( ArrayElementNode );
export var convert = ( node:Dynamic, types:String ) => nodeObject( new ConvertNode( nodeObject( node ), types ) );
export var split = ( node:Dynamic, channels:String ) => nodeObject( new SplitNode( nodeObject( node ), channels ) );

addNodeElement( 'element', element );
addNodeElement( 'convert', convert );