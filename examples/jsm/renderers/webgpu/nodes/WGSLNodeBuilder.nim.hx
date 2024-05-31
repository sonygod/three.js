import three.NoColorSpace;
import three.FloatType;

import node.NodeUniformsGroup;

import node.NodeSampler;
import node.NodeSampledTexture;
import node.NodeSampledCubeTexture;

import node.NodeUniformBuffer;
import node.NodeStorageBuffer;

import node.NodeBuilder;
import node.CodeNode;

import webgpu.WebGPUTextureUtils;

import wgsl.WGSLNodeParser;

// GPUShaderStage is not defined in browsers not supporting WebGPU
var GPUShaderStage = js.Browser.window.GPUShaderStage;

var gpuShaderStageLib = {
	'vertex': GPUShaderStage ? GPUShaderStage.VERTEX : 1,
	'fragment': GPUShaderStage ? GPUShaderStage.FRAGMENT : 2,
	'compute': GPUShaderStage ? GPUShaderStage.COMPUTE : 4
};

var supports = {
	instance: true,
	storageBuffer: true
};

var wgslFnOpLib = {
	'^^': 'threejs_xor'
};

var wgslTypeLib = {
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

var wgslMethods = {
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

var wgslPolyfill = {
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

	public function new( object:Dynamic, renderer:Dynamic, scene:Dynamic ) {

		super( object, renderer, new WGSLNodeParser(), scene );

		this.uniformGroups = new Map<String, NodeUniformsGroup>();

		this.builtins = new Map<String, Dynamic>();

	}

	public function needsColorSpaceToLinear( texture:Dynamic ):Bool {

		return texture.isVideoTexture === true && texture.colorSpace !== NoColorSpace;

	}

	private function _generateTextureSample( texture:Dynamic, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ) {

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

	private function _generateVideoSample( textureProperty:String, uvSnippet:String, shaderStage:String = this.shaderStage ) {

		if ( shaderStage === 'fragment' ) {

			return `textureSampleBaseClampToEdge( ${ textureProperty }, ${ textureProperty }_sampler, vec2<f32>( ${ uvSnippet }.x, 1.0 - ${ uvSnippet }.y ) )`;

		} else {

			trace( `WebGPURenderer: THREE.VideoTexture does not support ${ shaderStage } shader.` );

		}

	}

	private function _generateTextureSampleLevel( texture:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ) {

		if ( shaderStage === 'fragment' && this.isUnfilterable( texture ) === false ) {

			return `textureSampleLevel( ${ textureProperty }, ${ textureProperty }_sampler, ${ uvSnippet }, ${ levelSnippet } )`;

		} else {

			return this.generateTextureLod( texture, textureProperty, uvSnippet, levelSnippet );

		}

	}

	public function generateTextureLod( texture:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String = '0' ) {

		this._include( 'repeatWrapping' );

		var dimension = `textureDimensions( ${ textureProperty }, 0 )`;

		return `textureLoad( ${ textureProperty }, threejs_repeatWrapping( ${ uvSnippet }, ${ dimension } ), i32( ${ levelSnippet } ) )`;

	}

	public function generateTextureLoad( texture:Dynamic, textureProperty:String, uvIndexSnippet:String, depthSnippet:String, levelSnippet:String = '0u' ) {

		if ( depthSnippet ) {

			return `textureLoad( ${ textureProperty }, ${ uvIndexSnippet }, ${ depthSnippet }, ${ levelSnippet } )`;

		} else {

			return `textureLoad( ${ textureProperty }, ${ uvIndexSnippet }, ${ levelSnippet } )`;

		}

	}

	public function generateTextureStore( texture:Dynamic, textureProperty:String, uvIndexSnippet:String, valueSnippet:String ) {

		return `textureStore( ${ textureProperty }, ${ uvIndexSnippet }, ${ valueSnippet } )`;

	}

	public function isUnfilterable( texture:Dynamic ):Bool {

		return this.getComponentTypeFromTexture( texture ) !== 'float' || ( texture.isDataTexture === true && texture.type === FloatType );

	}

	public function generateTexture( texture:Dynamic, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ) {

		var snippet = null;

		if ( texture.isVideoTexture === true ) {

			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );

		} else if ( this.isUnfilterable( texture ) ) {

			snippet = this.generateTextureLod( texture, textureProperty, uvSnippet, '0', depthSnippet, shaderStage );

		} else {

			snippet = this._generateTextureSample( texture, textureProperty, uvSnippet, depthSnippet, shaderStage );

		}

		return snippet;

	}

	public function generateTextureGrad( texture:Dynamic, textureProperty:String, uvSnippet:String, gradSnippet:Array<String>, depthSnippet:String, shaderStage:String = this.shaderStage ) {

		if ( shaderStage === 'fragment' ) {

			// TODO handle i32 or u32 --> uvSnippet, array_index: A, ddx, ddy
			return `textureSampleGrad( ${ textureProperty }, ${ textureProperty }_sampler, ${ uvSnippet },  ${ gradSnippet[ 0 ] }, ${ gradSnippet[ 1 ] } )`;

		} else {

			trace( `WebGPURenderer: THREE.TextureNode.gradient() does not support ${ shaderStage } shader.` );

		}

	}

	public function generateTextureCompare( texture:Dynamic, textureProperty:String, uvSnippet:String, compareSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ) {

		if ( shaderStage === 'fragment' ) {

			return `textureSampleCompare( ${ textureProperty }, ${ textureProperty }_sampler, ${ uvSnippet }, ${ compareSnippet } )`;

		} else {

			trace( `WebGPURenderer: THREE.DepthTexture.compareFunction() does not support ${ shaderStage } shader.` );

		}

	}

	public function generateTextureLevel( texture:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ) {

		var snippet = null;

		if ( texture.isVideoTexture === true ) {

			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );

		} else {

			snippet = this._generateTextureSampleLevel( texture, textureProperty, uvSnippet, levelSnippet, depthSnippet, shaderStage );

		}

		return snippet;

	}

	override public function getPropertyName( node:Dynamic, shaderStage:String = this.shaderStage ) {

		if ( node.isNodeVarying === true && node.needsInterpolation === true ) {

			if ( shaderStage === 'vertex' ) {

				return `varyings.${ node.name }`;

			}

		} else if ( node.isNodeUniform === true ) {

			var name = node.name;
			var type = node.type;

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

	private function _getUniformGroupCount( shaderStage:String ) {

		return Object.keys( this.uniforms[ shaderStage ] ).length;

	}

	public function getFunctionOperator( op:String ):String {

		var fnOp = wgslFnOpLib[ op ];

		if ( fnOp !== undefined ) {

			this._include( fnOp );

			return fnOp;

		}

		return null;

	}

	override public function getUniformFromNode( node:Dynamic, type:String, shaderStage:String, name:String = null ) {

		var uniformNode = super.getUniformFromNode( node, type, shaderStage, name );
		var nodeData = this.getDataFromNode( node, shaderStage, this.globalCache );

		if ( nodeData.uniformGPU === undefined ) {

			var uniformGPU;

			var bindings = this.bindings[ shaderStage ];

			if ( type === 'texture' || type === 'cubeTexture' || type === 'storageTexture' ) {

				var texture = null;

				if ( type === 'texture' || type === 'storageTexture' ) {

					texture = new NodeSampledTexture( uniformNode.name, uniformNode.node );

				} else if ( type === 'cubeTexture' ) {

					texture = new NodeSampledCubeTexture( uniformNode.name, uniformNode.node );

				}

				texture.store = node.isStoreTextureNode === true;
				texture.setVisibility( gpuShaderStageLib[ shaderStage ] );

				if ( shaderStage === 'fragment' && this.isUnfilterable( node.value ) === false && texture.store === false ) {

					var sampler = new NodeSampler( `${uniformNode.name}_sampler`, uniformNode.node );
					sampler.setVisibility( gpuShaderStageLib[ shaderStage ] );

					bindings.push( sampler, texture );

					uniformGPU = [ sampler, texture ];

				} else {

					bindings.push( texture );

					uniformGPU = [ texture ];

				}

			} else if ( type === 'buffer' || type === 'storageBuffer' ) {

				var bufferClass = type === 'storageBuffer' ? NodeStorageBuffer : NodeUniformBuffer;
				var buffer = new bufferClass( node );
				buffer.setVisibility( gpuShaderStageLib[ shaderStage ] );

				bindings.push( buffer );

				uniformGPU = buffer;

			} else {

				var group = node.groupNode;
				var groupName = group.name;

				var uniformsStage = this.uniformGroups[ shaderStage ] || ( this.uniformGroups[ shaderStage ] = new Map<String, NodeUniformsGroup>() );

				var uniformsGroup = uniformsStage[ groupName ];

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

	override public function isReference( type:String ):Bool {

		return super.isReference( type ) || type === 'texture_2d' || type === 'texture_cube' || type === 'texture_depth_2d' || type === 'texture_storage_2d';

	}

	public function getBuiltin( name:String, property:String, type:String, shaderStage:String = this.shaderStage ) {

		var map = this.builtins[ shaderStage ] || ( this.builtins[ shaderStage ] = new Map<String, Dynamic>() );

		if ( map.has( name ) === false ) {

			map.set( name, {
				name,
				property,
				type
			} );

		}

		return property;

	}

	public function getVertexIndex() {

		if ( this.shaderStage === 'vertex' ) {

			return this.getBuiltin( 'vertex_index', 'vertexIndex', 'u32', 'attribute' );

		}

		return 'vertexIndex';

	}

	public function buildFunctionCode( shaderNode:Dynamic ) {

		var layout = shaderNode.layout;
		var flowData = this.flowShaderNode( shaderNode );

		var parameters = [];

		for ( var input in layout.inputs ) {

			parameters.push( input.name + ' : ' + this.getType( input.type ) );

		}

		//

		var code = `fn ${ layout.name }( ${ parameters.join( ', ' ) } ) -> ${ this.getType( layout.type ) } {
${ flowData.vars }
${ flowData.code }
	return ${ flowData.result };

}`;

		//

		return code;

	}

	public function getInstanceIndex() {

		if ( this.shaderStage === 'vertex' ) {

			return this.getBuiltin( 'instance_index', 'instanceIndex', 'u32', 'attribute' );

		}

		return 'instanceIndex';

	}

	public function getFrontFacing() {

		return this.getBuiltin( 'front_facing', 'isFront', 'bool' );

	}

	public function getFragCoord() {

		return this.getBuiltin( 'position', 'fragCoord', 'vec4<f32>' ) + '.xyz';

	}

	public function getFragDepth() {

		return 'output.' + this.getBuiltin( 'frag_depth', 'depth', 'f32', 'output' );

	}

	public function isFlipY() {

		return false;

	}

	public function getBuiltins( shaderStage:String ) {

		var snippets = [];
		var builtins = this.builtins[ shaderStage ];

		if ( builtins !== undefined ) {

			for ( var { name, property, type } in builtins.values() ) {

				snippets.push( `@builtin( ${name} ) ${property} : ${type}` );

			}

		}

		return snippets.join( ',\n\t' );

	}

	public function getAttributes( shaderStage:String ) {

		var snippets = [];

		if ( shaderStage === 'compute' ) {

			this.getBuiltin( 'global_invocation_id', 'id', 'vec3<u32>', 'attribute' );

		}

		if ( shaderStage === 'vertex' || shaderStage === 'compute' ) {

			var builtins = this.getBuiltins( 'attribute' );

			if ( builtins ) snippets.push( builtins );

			var attributes = this.getAttributesArray();

			for ( let index = 0, length = attributes.length; index < length; index ++ ) {

				var attribute = attributes[ index ];
				var name = attribute.name;
				var type = this.getType( attribute.type );

				snippets.push( `@location( ${index} ) ${ name } : ${ type }` );

			}

		}

		return snippets.join( ',\n\t' );

	}

	public function getStructMembers( struct:Dynamic ) {

		var snippets = [];
		var members = struct.getMemberTypes();

		for ( let i = 0; i < members.length; i ++ ) {

			var member = members[ i ];
			snippets.push( `\t@location( ${i} ) m${i} : ${ member }<f32>` );

		}

		return snippets.join( ',\n' );

	}

	public function getStructs( shaderStage:String ) {

		var snippets = [];
		var structs = this.structs[ shaderStage ];

		for ( let index = 0, length = structs.length; index < length; index ++ ) {

			var struct = structs[ index ];
			var name = struct.name;

			var snippet = `\struct ${ name } {\n`;
			snippet += this.getStructMembers( struct );
			snippet += '\n}';

			snippets.push( snippet );

		}

		return snippets.join( '\n\n' );

	}

	public function getVar( type:String, name:String ) {

		return `var ${ name } : ${ this.getType( type ) }`;

	}

	public function getVars( shaderStage:String ) {

		var snippets = [];
		var vars = this.vars[ shaderStage ];

		if ( vars !== undefined ) {

			for ( var variable in vars ) {

				snippets.push( `\t${ this.getVar( variable.type, variable.name ) };` );

			}

		}

		return `\n${ snippets.join( '\n' ) }\n`;

	}

	public function getVaryings( shaderStage:String ) {

		var snippets = [];

		if ( shaderStage === 'vertex' ) {

			this.getBuiltin( 'position', 'Vertex', 'vec4<f32>', 'vertex' );

		}

		if ( shaderStage === 'vertex' || shaderStage === 'fragment' ) {

			var varyings = this.varyings;
			var vars = this.vars[ shaderStage ];

			for ( let index = 0; index < varyings.length; index ++ ) {

				var varying = varyings[ index ];

				if ( varying.needsInterpolation ) {

					var attributesSnippet = `@location( ${index} )`;

					if ( /^(int|uint|ivec|uvec)/.test( varying.type ) ) {

						attributesSnippet += ' @interpolate( flat )';


					}

					snippets.push( `${ attributesSnippet } ${ varying.name } : ${ this.getType( varying.type ) }` );

				} else if ( shaderStage === 'vertex' && vars.includes( varying ) === false ) {

					vars.push( varying );

				}

			}

		}

		var builtins = this.getBuiltins( shaderStage );

		if ( builtins ) snippets.push( builtins );

		var code = snippets.join( ',\n\t' );

		return shaderStage === 'vertex' ? this._getWGSLStruct( 'VaryingsStruct', '\t' + code ) : code;

	}

	public function getUniforms( shaderStage:String ) {

		var uniforms = this.uniforms[ shaderStage ];

		var bindingSnippets = [];
		var bufferSnippets = [];
		var structSnippets = [];
		var uniformGroups = {};

		var index = this.bindingsOffset[ shaderStage ];

		for ( var uniform in uniforms ) {

			if ( uniform.type === 'texture' || uniform.type === 'cubeTexture' || uniform.type === 'storageTexture' ) {

				var texture = uniform.node.value;

				if ( shaderStage === 'fragment' && this.isUnfilterable( texture ) === false && uniform.node.isStoreTextureNode !== true ) {

					if ( texture.isDepthTexture === true && texture.compareFunction !== null ) {

						bindingSnippets.push( `@binding( ${index ++} ) @group( 0 ) var ${uniform.name}_sampler : sampler_comparison;` );

					} else {

						bindingSnippets.push( `@binding( ${index ++} ) @group( 0 ) var ${uniform.name}_sampler : sampler;` );

					}

				}

				var textureType;

				if ( texture.isCubeTexture === true ) {

					textureType = 'texture_cube<f32>';

				} else if ( texture.isDataArrayTexture === true ) {

					textureType = 'texture_2d_array<f32>';

				} else if ( texture.isDepthTexture === true ) {

					textureType = 'texture_depth_2d';

				} else if ( texture.isVideoTexture === true ) {

					textureType = 'texture_external';

				} else if ( uniform.node.isStoreTextureNode === true ) {

					var format = WebGPUTextureUtils.getFormat( texture );

					textureType = `texture_storage_2d<${ format }, write>`;

				} else {

					var componentPrefix = this.getComponentTypeFromTexture( texture ).charAt( 0 );

					textureType = `texture_2d<${ componentPrefix }32>`;

				}

				bindingSnippets.push( `@binding( ${index ++} ) @group( 0 ) var ${uniform.name} : ${textureType};` );

			} else if ( uniform.type === 'buffer' || uniform.type === 'storageBuffer' ) {

				var bufferNode = uniform.node;
				var bufferType = this.getType( bufferNode.bufferType );
				var bufferCount = bufferNode.bufferCount;

				var bufferCountSnippet = bufferCount > 0 ? ', ' + bufferCount : '';
				var bufferSnippet = `\t${uniform.name} : array< ${bufferType}${bufferCountSnippet} >\n`;
				var bufferAccessMode = bufferNode.isStorageBufferNode ? 'storage,read_write' : 'uniform';

				bufferSnippets.push( this._getWGSLStructBinding( 'NodeBuffer_' + bufferNode.id, bufferSnippet, bufferAccessMode, index ++ ) );

			} else {

				var vectorType = this.getType( this.getVectorType( uniform.type ) );
				var groupName = uniform.groupNode.name;

				var group = uniformGroups[ groupName ] || ( uniformGroups[ groupName ] = {
					index: index ++,
					snippets: []
				} );

				group.snippets.push( `\t${ uniform.name } : ${ vectorType }` );

			}

		}

		for ( var name in uniformGroups ) {

			var group = uniformGroups[ name ];

			structSnippets.push( this._getWGSLStructBinding( name, group.snippets.join( ',\n' ), 'uniform', group.index ) );

		}

		var code = bindingSnippets.join( '\n' );
		code += bufferSnippets.join( '\n' );
		code += structSnippets.join( '\n' );

		return code;

	}

	public function buildCode() {

		var shadersData = this.material !== null ? { fragment: {}, vertex: {} } : { compute: {} };

		for ( var shaderStage in shadersData ) {

			var stageData = shadersData[ shaderStage ];
			stageData.uniforms = this.getUniforms( shaderStage );
			stageData.attributes = this.getAttributes( shaderStage );
			stageData.varyings = this.getVaryings( shaderStage );
			stageData.structs = this.getStructs( shaderStage );
			stageData.vars = this.getVars( shaderStage );
			stageData.codes = this.getCodes( shaderStage );

			//

			var flow = '// code\n\n';
			flow += this.flowCode[ shaderStage ];

			var flowNodes = this.flowNodes[ shaderStage ];
			var mainNode = flowNodes[ flowNodes.length - 1 ];

			var outputNode = mainNode.outputNode;
			var isOutputStruct = ( outputNode !== undefined && outputNode.isOutputStructNode === true );

			for ( var node in flowNodes ) {

				var flowSlotData = this.getFlowData( node/*, shaderStage*/ );
				var slotName = node.name;

				if ( slotName ) {

					if ( flow.length > 0 ) flow += '\n';

					flow += `\t// flow -> ${ slotName }\n\t`;

				}

				flow += `${ flowSlotData.code }\n\t`;

				if ( node === mainNode && shaderStage !== 'compute' ) {

					flow += '// result\n\n\t';

					if ( shaderStage === 'vertex' ) {

						flow += `varyings.Vertex = ${ flowSlotData.result };`;

					} else if ( shaderStage === 'fragment' ) {

						if ( isOutputStruct ) {

							stageData.returnType = outputNode.nodeType;

							flow += `return ${ flowSlotData.result };`;

						} else {

							var structSnippet = '\t@location(0) color: vec4<f32>';

							var builtins = this.getBuiltins( 'output' );

							if ( builtins ) structSnippet += ',\n\t' + builtins;

							stageData.returnType = 'OutputStruct';
							stageData.structs += this._getWGSLStruct( 'OutputStruct', structSnippet );
							stageData.structs += '\nvar<private> output : OutputStruct;\n\n';

							flow += `output.color = ${ flowSlotData.result };\n\n\treturn output;`;

						}

					}

				}

			}

			stageData.flow = flow;

		}

		if ( this.material !== null ) {

			this.vertexShader = this._getWGSLVertexCode( shadersData.vertex );
			this.fragmentShader = this._getWGSLFragmentCode( shadersData.fragment );

		} else {

			this.computeShader = this._getWGSLComputeCode( shadersData.compute, ( this.object.workgroupSize || [ 64 ] ).join( ', ' ) );

		}

	}

	public function getMethod( method:String, output:String = null ) {

		var wgslMethod;

		if ( output !== null ) {

			wgslMethod = this._getWGSLMethod( method + '_' + output );

		}

		if ( wgslMethod === undefined ) {

			wgslMethod = this._getWGSLMethod( method );

		}

		return wgslMethod || method;

	}

	public function getType( type:String ):String {

		return wgslTypeLib[ type ] || type;

	}

	public function isAvailable( name:String ):Bool {

		return supports[ name ] === true;

	}

	private function _getWGSLMethod( method:String ):String {

		if ( wgslPolyfill[ method ] !== undefined ) {

			this._include( method );

		}

		return wgslMethods[ method ];

	}

	private function _include( name:String ) {

		var codeNode = wgslPolyfill[ name ];
		codeNode.build( this );

		if ( this.currentFunctionNode !== null ) {

			this.currentFunctionNode.includes.push( codeNode );

		}

		return codeNode;

	}

	private function _getWGSLVertexCode( shaderData:Dynamic ) {

		return `${ this.getSignature() }

// uniforms
${shaderData.uniforms}

// varyings
${shaderData.varyings}
var<private> varyings : VaryingsStruct;

// codes
${shaderData.codes}

@vertex
fn main( ${shaderData.attributes} ) -> VaryingsStruct {

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

	return varyings;

}
`;

	}

	private function _getWGSLFragmentCode( shaderData:Dynamic ) {

		return `${ this.getSignature() }

// uniforms
${shaderData.uniforms}

// structs
${shaderData.structs}

// codes
${shaderData.codes}

@fragment
fn main( ${shaderData.varyings} ) -> ${shaderData.returnType} {

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

}
`;

	}

	private function _getWGSLComputeCode( shaderData:Dynamic, workgroupSize:String ) {

		return `${ this.getSignature() }
// system
var<private> instanceIndex : u32;

// uniforms
${shaderData.uniforms}

// codes
${shaderData.codes}

@compute @workgroup_size( ${workgroupSize} )
fn main( ${shaderData.attributes} ) {

	// system
	instanceIndex = id.x;

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

}
`;

	}

	private function _getWGSLStruct( name:String, vars:String ) {

		return `
struct ${name} {
${vars}
};`;

	}

	private function _getWGSLStructBinding( name:String, vars:String, access:String, binding:Int = 0, group:Int = 0 ) {

		var structName = name + 'Struct';
		var structSnippet = this._getWGSLStruct( structName, vars );

		return `${structSnippet}
@binding( ${binding} ) @group( ${group} )
var<${access}> ${name} : ${structName};`;

	}

}