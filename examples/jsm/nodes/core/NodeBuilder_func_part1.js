import NodeUniform from './NodeUniform.js';
import NodeAttribute from './NodeAttribute.js';
import NodeVarying from './NodeVarying.js';
import NodeVar from './NodeVar.js';
import NodeCode from './NodeCode.js';
import NodeKeywords from './NodeKeywords.js';
import NodeCache from './NodeCache.js';
import ParameterNode from './ParameterNode.js';
import FunctionNode from '../code/FunctionNode.js';
import { createNodeMaterialFromType, default as NodeMaterial } from '../materials/NodeMaterial.js';
import { NodeUpdateType, defaultBuildStages, shaderStages } from './constants.js';

import {
	FloatNodeUniform, Vector2NodeUniform, Vector3NodeUniform, Vector4NodeUniform,
	ColorNodeUniform, Matrix3NodeUniform, Matrix4NodeUniform
} from '../../renderers/common/nodes/NodeUniform.js';

import { REVISION, RenderTarget, Color, Vector2, Vector3, Vector4, IntType, UnsignedIntType, Float16BufferAttribute } from 'three';

import { stack } from './StackNode.js';
import { getCurrentStack, setCurrentStack } from '../shadernode/ShaderNode.js';

import CubeRenderTarget from '../../renderers/common/CubeRenderTarget.js';
import ChainMap from '../../renderers/common/ChainMap.js';

import PMREMGenerator from '../../renderers/common/extras/PMREMGenerator.js';

const uniformsGroupCache = new ChainMap();

const typeFromLength = new Map( [
	[ 2, 'vec2' ],
	[ 3, 'vec3' ],
	[ 4, 'vec4' ],
	[ 9, 'mat3' ],
	[ 16, 'mat4' ]
] );

const typeFromArray = new Map( [
	[ Int8Array, 'int' ],
	[ Int16Array, 'int' ],
	[ Int32Array, 'int' ],
	[ Uint8Array, 'uint' ],
	[ Uint16Array, 'uint' ],
	[ Uint32Array, 'uint' ],
	[ Float32Array, 'float' ]
] );

const toFloat = ( value ) => {

	value = Number( value );

	return value + ( value % 1 ? '' : '.0' );

};


class NodeBuilder {

	constructor( object, renderer, parser, scene = null, material = null ) {

		this.object = object;
		this.material = material || ( object && object.material ) || null;
		this.geometry = ( object && object.geometry ) || null;
		this.renderer = renderer;
		this.parser = parser;
		this.scene = scene;

		this.nodes = [];
		this.updateNodes = [];
		this.updateBeforeNodes = [];
		this.hashNodes = {};

		this.lightsNode = null;
		this.environmentNode = null;
		this.fogNode = null;

		this.clippingContext = null;

		this.vertexShader = null;
		this.fragmentShader = null;
		this.computeShader = null;

		this.flowNodes = { vertex: [], fragment: [], compute: [] };
		this.flowCode = { vertex: '', fragment: '', compute: [] };
		this.uniforms = { vertex: [], fragment: [], compute: [], index: 0 };
		this.structs = { vertex: [], fragment: [], compute: [], index: 0 };
		this.bindings = { vertex: [], fragment: [], compute: [] };
		this.bindingsOffset = { vertex: 0, fragment: 0, compute: 0 };
		this.bindingsArray = null;
		this.attributes = [];
		this.bufferAttributes = [];
		this.varyings = [];
		this.codes = {};
		this.vars = {};
		this.flow = { code: '' };
		this.chaining = [];
		this.stack = stack();
		this.stacks = [];
		this.tab = '\t';

		this.currentFunctionNode = null;

		this.context = {
			keywords: new NodeKeywords(),
			material: this.material
		};

		this.cache = new NodeCache();
		this.globalCache = this.cache;

		this.flowsData = new WeakMap();

		this.shaderStage = null;
		this.buildStage = null;

	}
createRenderTarget( width, height, options ) {

		return new RenderTarget( width, height, options );

	}
createCubeRenderTarget( size, options ) {

		return new CubeRenderTarget( size, options );

	}
createPMREMGenerator() {

		// TODO: Move Materials.js to outside of the Nodes.js in order to remove this function and improve tree-shaking support

		return new PMREMGenerator( this.renderer );

	}
includes( node ) {

		return this.nodes.includes( node );

	}
_getSharedBindings( bindings ) {

		const shared = [];

		for ( const binding of bindings ) {

			if ( binding.shared === true ) {

				// nodes is the chainmap key
				const nodes = binding.getNodes();

				let sharedBinding = uniformsGroupCache.get( nodes );

				if ( sharedBinding === undefined ) {

					uniformsGroupCache.set( nodes, binding );

					sharedBinding = binding;

				}

				shared.push( sharedBinding );

			} else {

				shared.push( binding );

			}

		}

		return shared;

	}
getBindings() {

		let bindingsArray = this.bindingsArray;

		if ( bindingsArray === null ) {

			const bindings = this.bindings;

			this.bindingsArray = bindingsArray = this._getSharedBindings( ( this.material !== null ) ? [ ...bindings.vertex, ...bindings.fragment ] : bindings.compute );

		}

		return bindingsArray;

	}
setHashNode( node, hash ) {

		this.hashNodes[ hash ] = node;

	}
addNode( node ) {

		if ( this.nodes.includes( node ) === false ) {

			this.nodes.push( node );

			this.setHashNode( node, node.getHash( this ) );

		}

	}
buildUpdateNodes() {

		for ( const node of this.nodes ) {

			const updateType = node.getUpdateType();
			const updateBeforeType = node.getUpdateBeforeType();

			if ( updateType !== NodeUpdateType.NONE ) {

				this.updateNodes.push( node.getSelf() );

			}

			if ( updateBeforeType !== NodeUpdateType.NONE ) {

				this.updateBeforeNodes.push( node );

			}

		}

	}
get currentNode() {

		return this.chaining[ this.chaining.length - 1 ];

	}
addChain( node ) {

		/*
		if ( this.chaining.indexOf( node ) !== - 1 ) {

			console.warn( 'Recursive node: ', node );

		}
		*/

		this.chaining.push( node );

	}
removeChain( node ) {

		const lastChain = this.chaining.pop();

		if ( lastChain !== node ) {

			throw new Error( 'NodeBuilder: Invalid node chaining!' );

		}

	}
getMethod( method ) {

		return method;

	}
getNodeFromHash( hash ) {

		return this.hashNodes[ hash ];

	}
addFlow( shaderStage, node ) {

		this.flowNodes[ shaderStage ].push( node );

		return node;

	}
setContext( context ) {

		this.context = context;

	}
getContext() {

		return this.context;

	}
setCache( cache ) {

		this.cache = cache;

	}
getCache() {

		return this.cache;

	}
isAvailable( /*name*/ ) {

		return false;

	}
getVertexIndex() {

		console.warn( 'Abstract function.' );

	}
getInstanceIndex() {

		console.warn( 'Abstract function.' );

	}
getFrontFacing() {

		console.warn( 'Abstract function.' );

	}
getFragCoord() {

		console.warn( 'Abstract function.' );

	}
isFlipY() {

		return false;

	}
generateTexture( /* texture, textureProperty, uvSnippet */ ) {

		console.warn( 'Abstract function.' );

	}
generateTextureLod( /* texture, textureProperty, uvSnippet, levelSnippet */ ) {

		console.warn( 'Abstract function.' );

	}
generateConst( type, value = null ) {

		if ( value === null ) {

			if ( type === 'float' || type === 'int' || type === 'uint' ) value = 0;
			else if ( type === 'bool' ) value = false;
			else if ( type === 'color' ) value = new Color();
			else if ( type === 'vec2' ) value = new Vector2();
			else if ( type === 'vec3' ) value = new Vector3();
			else if ( type === 'vec4' ) value = new Vector4();

		}

		if ( type === 'float' ) return toFloat( value );
		if ( type === 'int' ) return `${ Math.round( value ) }`;
		if ( type === 'uint' ) return value >= 0 ? `${ Math.round( value ) }u` : '0u';
		if ( type === 'bool' ) return value ? 'true' : 'false';
		if ( type === 'color' ) return `${ this.getType( 'vec3' ) }( ${ toFloat( value.r ) }, ${ toFloat( value.g ) }, ${ toFloat( value.b ) } )`;

		const typeLength = this.getTypeLength( type );

		const componentType = this.getComponentType( type );

		const generateConst = value => this.generateConst( componentType, value );

		if ( typeLength === 2 ) {

			return `${ this.getType( type ) }( ${ generateConst( value.x ) }, ${ generateConst( value.y ) } )`;

		} else if ( typeLength === 3 ) {

			return `${ this.getType( type ) }( ${ generateConst( value.x ) }, ${ generateConst( value.y ) }, ${ generateConst( value.z ) } )`;

		} else if ( typeLength === 4 ) {

			return `${ this.getType( type ) }( ${ generateConst( value.x ) }, ${ generateConst( value.y ) }, ${ generateConst( value.z ) }, ${ generateConst( value.w ) } )`;

		} else if ( typeLength > 4 && value && ( value.isMatrix3 || value.isMatrix4 ) ) {

			return `${ this.getType( type ) }( ${ value.elements.map( generateConst ).join( ', ' ) } )`;

		} else if ( typeLength > 4 ) {

			return `${ this.getType( type ) }()`;

		}

		throw new Error( `NodeBuilder: Type '${type}' not found in generate constant attempt.` );

	}
getType( type ) {

		if ( type === 'color' ) return 'vec3';

		return type;

	}
generateMethod( method ) {

		return method;

	}
hasGeometryAttribute( name ) {

		return this.geometry && this.geometry.getAttribute( name ) !== undefined;

	}
getAttribute( name, type ) {

		const attributes = this.attributes;

		// find attribute

		for ( const attribute of attributes ) {

			if ( attribute.name === name ) {

				return attribute;

			}

		}

		// create a new if no exist

		const attribute = new NodeAttribute( name, type );

		attributes.push( attribute );

		return attribute;

	}
getPropertyName( node/*, shaderStage*/ ) {

		return node.name;

	}
isVector( type ) {

		return /vec\d/.test( type );

	}
isMatrix( type ) {

		return /mat\d/.test( type );

	}
isReference( type ) {

		return type === 'void' || type === 'property' || type === 'sampler' || type === 'texture' || type === 'cubeTexture' || type === 'storageTexture';

	}
needsColorSpaceToLinear( /*texture*/ ) {

		return false;

	}
getComponentTypeFromTexture( texture ) {

		const type = texture.type;

		if ( texture.isDataTexture ) {

			if ( type === IntType ) return 'int';
			if ( type === UnsignedIntType ) return 'uint';

		}

		return 'float';

	}
getComponentType( type ) {

		type = this.getVectorType( type );

		if ( type === 'float' || type === 'bool' || type === 'int' || type === 'uint' ) return type;

		const componentType = /(b|i|u|)(vec|mat)([2-4])/.exec( type );

		if ( componentType === null ) return null;

		if ( componentType[ 1 ] === 'b' ) return 'bool';
		if ( componentType[ 1 ] === 'i' ) return 'int';
		if ( componentType[ 1 ] === 'u' ) return 'uint';

		return 'float';

	}
getVectorType( type ) {

		if ( type === 'color' ) return 'vec3';
		if ( type === 'texture' || type === 'cubeTexture' || type === 'storageTexture' ) return 'vec4';

		return type;

	}
getTypeFromLength( length, componentType = 'float' ) {

		if ( length === 1 ) return componentType;

		const baseType = typeFromLength.get( length );
		const prefix = componentType === 'float' ? '' : componentType[ 0 ];

		return prefix + baseType;

	}