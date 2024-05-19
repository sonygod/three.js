import { NoColorSpace, FloatType } from 'three';

import NodeUniformsGroup from '../../common/nodes/NodeUniformsGroup.js';

import NodeSampler from '../../common/nodes/NodeSampler.js';
import { NodeSampledTexture, NodeSampledCubeTexture } from '../../common/nodes/NodeSampledTexture.js';

import NodeUniformBuffer from '../../common/nodes/NodeUniformBuffer.js';
import NodeStorageBuffer from '../../common/nodes/NodeStorageBuffer.js';

import { NodeBuilder, CodeNode } from '../../../nodes/Nodes.js';

import { getFormat } from '../utils/WebGPUTextureUtils.js';

import WGSLNodeParser from './WGSLNodeParser.js';

// GPUShaderStage is not defined in browsers not supporting WebGPU
const GPUShaderStage = self.GPUShaderStage;

const gpuShaderStageLib = {
	'vertex': GPUShaderStage ? GPUShaderStage.VERTEX : 1,
	'fragment': GPUShaderStage ? GPUShaderStage.FRAGMENT : 2,
	'compute': GPUShaderStage ? GPUShaderStage.COMPUTE : 4
};

const supports = {
	instance: true,
	storageBuffer: true
};

const wgslFnOpLib = {
	'^^': 'threejs_xor'
};

const wgslTypeLib = {
	float: 'f32',
	int: 'i32',
	uint: 'u32',
	bool: 'bool',
	color: 'vec3<f32>',

	vec2: 'vec2<f32>',
	ivec2: 'vec2<i32>',
	uvec2: 'vec2<u32>',
	bvec2: 'vec2<bool>',

	vec3: 'vec3<f32>',
	ivec3: 'vec3<i32>',
	uvec3: 'vec3<u32>',
	bvec3: 'vec3<bool>',

	vec4: 'vec4<f32>',
	ivec4: 'vec4<i32>',
	uvec4: 'vec4<u32>',
	bvec4: 'vec4<bool>',

	mat2: 'mat2x2<f32>',
	imat2: 'mat2x2<i32>',
	umat2: 'mat2x2<u32>',
	bmat2: 'mat2x2<bool>',

	mat3: 'mat3x3<f32>',
	imat3: 'mat3x3<i32>',
	umat3: 'mat3x3<u32>',
	bmat3: 'mat3x3<bool>',

	mat4: 'mat4x4<f32>',
	imat4: 'mat4x4<i32>',
	umat4: 'mat4x4<u32>',
	bmat4: 'mat4x4<bool>'
};

const wgslMethods = {
	dFdx: 'dpdx',
	dFdy: '- dpdy',
	mod_float: 'threejs_mod_float',
	mod_vec2: 'threejs_mod_vec2',
	mod_vec3: 'threejs_mod_vec3',
	mod_vec4: 'threejs_mod_vec4',
	equals_bool: 'threejs_equals_bool',
	equals_bvec2: 'threejs_equals_bvec2',
	equals_bvec3: 'threejs_equals_bvec3',
	equals_bvec4: 'threejs_equals_bvec4',
	lessThanEqual: 'threejs_lessThanEqual',
	greaterThan: 'threejs_greaterThan',
	inversesqrt: 'inverseSqrt',
	bitcast: 'bitcast<f32>'
};

const wgslPolyfill = {
	threejs_xor: new CodeNode( `
fn threejs_xor( a : bool, b : bool ) -> bool {

	return ( a || b ) && !( a && b );

}
` ),
	lessThanEqual: new CodeNode( `
fn threejs_lessThanEqual( a : vec3<f32>, b : vec3<f32> ) -> vec3<bool> {

	return vec3<bool>( a.x <= b.x, a.y <= b.y, a.z <= b.z );

}
` ),
	greaterThan: new CodeNode( `
fn threejs_greaterThan( a : vec3<f32>, b : vec3<f32> ) -> vec3<bool> {

	return vec3<bool>( a.x > b.x, a.y > b.y, a.z > b.z );

}
` ),
	mod_float: new CodeNode( 'fn threejs_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }' ),
	mod_vec2: new CodeNode( 'fn threejs_mod_vec2( x : vec2f, y : vec2f ) -> vec2f { return x - y * floor( x / y ); }' ),
	mod_vec3: new CodeNode( 'fn threejs_mod_vec3( x : vec3f, y : vec3f ) -> vec3f { return x - y * floor( x / y ); }' ),
	mod_vec4: new CodeNode( 'fn threejs_mod_vec4( x : vec4f, y : vec4f ) -> vec4f { return x - y * floor( x / y ); }' ),
	equals_bool: new CodeNode( 'fn threejs_equals_bool( a : bool, b : bool ) -> bool { return a == b; }' ),
	equals_bvec2: new CodeNode( 'fn threejs_equals_bvec2( a : vec2f, b : vec2f ) -> vec2<bool> { return vec2<bool>( a.x == b.x, a.y == b.y ); }' ),
	equals_bvec3: new CodeNode( 'fn threejs_equals_bvec3( a : vec3f, b : vec3f ) -> vec3<bool> { return vec3<bool>( a.x == b.x, a.y == b.y, a.z == b.z ); }' ),
	equals_bvec4: new CodeNode( 'fn threejs_equals_bvec4( a : vec4f, b : vec4f ) -> vec4<bool> { return vec4<bool>( a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w ); }' ),
	repeatWrapping: new CodeNode( `
fn threejs_repeatWrapping( uv : vec2<f32>, dimension : vec2<u32> ) -> vec2<u32> {

	let uvScaled = vec2<u32>( uv * vec2<f32>( dimension ) );

	return ( ( uvScaled % dimension ) + dimension ) % dimension;

}
` )
};


class WGSLNodeBuilder extends NodeBuilder {

	constructor( object, renderer, scene = null ) {

		super( object, renderer, new WGSLNodeParser(), scene );

		this.uniformGroups = {};

		this.builtins = {};

	}
needsColorSpaceToLinear( texture ) {

		return texture.isVideoTexture === true && texture.colorSpace !== NoColorSpace;

	}
_generateTextureSample( texture, textureProperty, uvSnippet, depthSnippet, shaderStage = this.shaderStage ) {

		if ( shaderStage === 'fragment' ) {

			if ( depthSnippet ) {

				return `textureSample( ${ textureProperty }, ${ textureProperty }_sampler, ${ uvSnippet }, ${ depthSnippet } )`;

			} else {

				return `textureSample( ${ textureProperty }, ${ textureProperty }_sampler, ${ uvSnippet } )`;

			}

		} else {

			return this.generateTextureLod( texture, textureProperty, uvSnippet );

		}

	}
_generateVideoSample( textureProperty, uvSnippet, shaderStage = this.shaderStage ) {

		if ( shaderStage === 'fragment' ) {

			return `textureSampleBaseClampToEdge( ${ textureProperty }, ${ textureProperty }_sampler, vec2<f32>( ${ uvSnippet }.x, 1.0 - ${ uvSnippet }.y ) )`;

		} else {

			console.error( `WebGPURenderer: THREE.VideoTexture does not support ${ shaderStage } shader.` );

		}

	}
_generateTextureSampleLevel( texture, textureProperty, uvSnippet, levelSnippet, depthSnippet, shaderStage = this.shaderStage ) {

		if ( shaderStage === 'fragment' && this.isUnfilterable( texture ) === false ) {

			return `textureSampleLevel( ${ textureProperty }, ${ textureProperty }_sampler, ${ uvSnippet }, ${ levelSnippet } )`;

		} else {

			return this.generateTextureLod( texture, textureProperty, uvSnippet, levelSnippet );

		}

	}
generateTextureLod( texture, textureProperty, uvSnippet, levelSnippet = '0' ) {

		this._include( 'repeatWrapping' );

		const dimension = `textureDimensions( ${ textureProperty }, 0 )`;

		return `textureLoad( ${ textureProperty }, threejs_repeatWrapping( ${ uvSnippet }, ${ dimension } ), i32( ${ levelSnippet } ) )`;

	}
generateTextureLoad( texture, textureProperty, uvIndexSnippet, depthSnippet, levelSnippet = '0u' ) {

		if ( depthSnippet ) {

			return `textureLoad( ${ textureProperty }, ${ uvIndexSnippet }, ${ depthSnippet }, ${ levelSnippet } )`;

		} else {

			return `textureLoad( ${ textureProperty }, ${ uvIndexSnippet }, ${ levelSnippet } )`;

		}

	}
generateTextureStore( texture, textureProperty, uvIndexSnippet, valueSnippet ) {

		return `textureStore( ${ textureProperty }, ${ uvIndexSnippet }, ${ valueSnippet } )`;

	}
isUnfilterable( texture ) {

		return this.getComponentTypeFromTexture( texture ) !== 'float' || ( texture.isDataTexture === true && texture.type === FloatType );

	}
generateTexture( texture, textureProperty, uvSnippet, depthSnippet, shaderStage = this.shaderStage ) {

		let snippet = null;

		if ( texture.isVideoTexture === true ) {

			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );

		} else if ( this.isUnfilterable( texture ) ) {

			snippet = this.generateTextureLod( texture, textureProperty, uvSnippet, '0', depthSnippet, shaderStage );

		} else {

			snippet = this._generateTextureSample( texture, textureProperty, uvSnippet, depthSnippet, shaderStage );

		}

		return snippet;

	}
generateTextureGrad( texture, textureProperty, uvSnippet, gradSnippet, depthSnippet, shaderStage = this.shaderStage ) {

		if ( shaderStage === 'fragment' ) {

			// TODO handle i32 or u32 --> uvSnippet, array_index: A, ddx, ddy
			return `textureSampleGrad( ${ textureProperty }, ${ textureProperty }_sampler, ${ uvSnippet },  ${ gradSnippet[ 0 ] }, ${ gradSnippet[ 1 ] } )`;

		} else {

			console.error( `WebGPURenderer: THREE.TextureNode.gradient() does not support ${ shaderStage } shader.` );

		}

	}
generateTextureCompare( texture, textureProperty, uvSnippet, compareSnippet, depthSnippet, shaderStage = this.shaderStage ) {

		if ( shaderStage === 'fragment' ) {

			return `textureSampleCompare( ${ textureProperty }, ${ textureProperty }_sampler, ${ uvSnippet }, ${ compareSnippet } )`;

		} else {

			console.error( `WebGPURenderer: THREE.DepthTexture.compareFunction() does not support ${ shaderStage } shader.` );

		}

	}
generateTextureLevel( texture, textureProperty, uvSnippet, levelSnippet, depthSnippet, shaderStage = this.shaderStage ) {

		let snippet = null;

		if ( texture.isVideoTexture === true ) {

			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );

		} else {

			snippet = this._generateTextureSampleLevel( texture, textureProperty, uvSnippet, levelSnippet, depthSnippet, shaderStage );

		}

		return snippet;

	}
getPropertyName( node, shaderStage = this.shaderStage ) {

		if ( node.isNodeVarying === true && node.needsInterpolation === true ) {

			if ( shaderStage === 'vertex' ) {

				return `varyings.${ node.name }`;

			}

		} else if ( node.isNodeUniform === true ) {

			const name = node.name;
			const type = node.type;

			if ( type === 'texture' || type === 'cubeTexture' || type === 'storageTexture' ) {

				return name;

			} else if ( type === 'buffer' || type === 'storageBuffer' ) {

				return `NodeBuffer_${ node.id }.${name}`;

			} else {

				return node.groupNode.name + '.' + name;

			}

		}

		return super.getPropertyName( node );

	}
_getUniformGroupCount( shaderStage ) {

		return Object.keys( this.uniforms[ shaderStage ] ).length;

	}
getFunctionOperator( op ) {

		const fnOp = wgslFnOpLib[ op ];

		if ( fnOp !== undefined ) {

			this._include( fnOp );

			return fnOp;

		}

		return null;

	}
getUniformFromNode( node, type, shaderStage, name = null ) {

		const uniformNode = super.getUniformFromNode( node, type, shaderStage, name );
		const nodeData = this.getDataFromNode( node, shaderStage, this.globalCache );

		if ( nodeData.uniformGPU === undefined ) {

			let uniformGPU;

			const bindings = this.bindings[ shaderStage ];

			if ( type === 'texture' || type === 'cubeTexture' || type === 'storageTexture' ) {

				let texture = null;

				if ( type === 'texture' || type === 'storageTexture' ) {

					texture = new NodeSampledTexture( uniformNode.name, uniformNode.node );

				} else if ( type === 'cubeTexture' ) {

					texture = new NodeSampledCubeTexture( uniformNode.name, uniformNode.node );

				}

				texture.store = node.isStoreTextureNode === true;
				texture.setVisibility( gpuShaderStageLib[ shaderStage ] );

				if ( shaderStage === 'fragment' && this.isUnfilterable( node.value ) === false && texture.store === false ) {

					const sampler = new NodeSampler( `${uniformNode.name}_sampler`, uniformNode.node );
					sampler.setVisibility( gpuShaderStageLib[ shaderStage ] );

					bindings.push( sampler, texture );

					uniformGPU = [ sampler, texture ];

				} else {

					bindings.push( texture );

					uniformGPU = [ texture ];

				}

			} else if ( type === 'buffer' || type === 'storageBuffer' ) {

				const bufferClass = type === 'storageBuffer' ? NodeStorageBuffer : NodeUniformBuffer;
				const buffer = new bufferClass( node );
				buffer.setVisibility( gpuShaderStageLib[ shaderStage ] );

				bindings.push( buffer );

				uniformGPU = buffer;

			} else {

				const group = node.groupNode;
				const groupName = group.name;

				const uniformsStage = this.uniformGroups[ shaderStage ] || ( this.uniformGroups[ shaderStage ] = {} );

				let uniformsGroup = uniformsStage[ groupName ];

				if ( uniformsGroup === undefined ) {

					uniformsGroup = new NodeUniformsGroup( groupName, group );
					uniformsGroup.setVisibility( gpuShaderStageLib[ shaderStage ] );

					uniformsStage[ groupName ] = uniformsGroup;

					bindings.push( uniformsGroup );

				}

				uniformGPU = this.getNodeUniform( uniformNode, type );

				uniformsGroup.addUniform( uniformGPU );

			}

			nodeData.uniformGPU = uniformGPU;

			if ( shaderStage === 'vertex' ) {

				this.bindingsOffset[ 'fragment' ] = bindings.length;

			}

		}

		return uniformNode;

	}
isReference( type ) {

		return super.isReference( type ) || type === 'texture_2d' || type === 'texture_cube' || type === 'texture_depth_2d' || type === 'texture_storage_2d';

	}
getBuiltin( name, property, type, shaderStage = this.shaderStage ) {

		const map = this.builtins[ shaderStage ] || ( this.builtins[ shaderStage ] = new Map() );

		if ( map.has( name ) === false ) {

			map.set( name, {
				name,
				property,
				type
			} );

		}

		return property;

	}
getVertexIndex() {

		if ( this.shaderStage === 'vertex' ) {

			return this.getBuiltin( 'vertex_index', 'vertexIndex', 'u32', 'attribute' );

		}

		return 'vertexIndex';

	}
buildFunctionCode( shaderNode ) {

		const layout = shaderNode.layout;
		const flowData = this.flowShaderNode( shaderNode );

		const parameters = [];

		for ( const input of layout.inputs ) {

			parameters.push( input.name + ' : ' + this.getType( input.type ) );

		}

		//

		const code = `fn ${ layout.name }( ${ parameters.join( ', ' ) } ) -> ${ this.getType( layout.type ) } {
${ flowData.vars }
${ flowData.code }
	return ${ flowData.result };

}`;

		//

		return code;

	}