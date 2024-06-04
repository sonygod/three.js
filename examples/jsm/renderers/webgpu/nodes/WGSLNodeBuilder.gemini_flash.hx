import three.NoColorSpace;
import three.FloatType;
import three.nodes.Node;
import three.nodes.NodeBuilder;
import three.nodes.NodeVarying;
import three.nodes.NodeUniform;
import three.nodes.NodeAttribute;
import three.nodes.NodeFunction;
import three.nodes.NodeFunctionCall;
import three.nodes.NodeTexture;
import three.nodes.NodeCubeTexture;
import three.nodes.NodeSampledTexture;
import three.nodes.NodeSampledCubeTexture;
import three.nodes.NodeSampler;
import three.nodes.NodeUniformBuffer;
import three.nodes.NodeStorageBuffer;
import three.nodes.NodeOutputStruct;
import three.nodes.NodeOutput;
import three.nodes.NodeColor;
import three.nodes.NodeTextureStore;
import three.nodes.NodeTextureLoad;
import three.nodes.NodeTextureGrad;
import three.nodes.NodeTextureCompare;
import three.nodes.NodeTextureLevel;
import three.nodes.NodeFloat;
import three.nodes.NodeVec2;
import three.nodes.NodeVec3;
import three.nodes.NodeVec4;
import three.nodes.NodeBool;
import three.nodes.NodeInt;
import three.nodes.NodeUint;
import three.nodes.NodeMat2;
import three.nodes.NodeMat3;
import three.nodes.NodeMat4;
import three.nodes.NodeMath;
import three.nodes.NodeMath2;
import three.nodes.NodeMath3;
import three.nodes.NodeMath4;
import three.nodes.NodeOperator;
import three.nodes.NodeFunction2;
import three.nodes.NodeFunction3;
import three.nodes.NodeFunction4;
import three.nodes.NodeStruct;
import three.nodes.NodeStructMember;
import three.nodes.NodeVar;
import three.nodes.NodeVar2;
import three.nodes.NodeVar3;
import three.nodes.NodeVar4;
import three.nodes.NodeVarying2;
import three.nodes.NodeVarying3;
import three.nodes.NodeVarying4;
import three.nodes.NodeCallFunction;
import three.nodes.CodeNode;
import three.math.Color;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Matrix4;
import three.math.Matrix3;
import three.math.Matrix2;
import three.textures.DataTexture;
import three.textures.DepthTexture;
import three.textures.Texture;
import three.textures.CubeTexture;
import three.textures.VideoTexture;
import three.materials.Material;
import three.renderers.webgpu.WebGPUTextureUtils;
import three.renderers.webgpu.WGSLNodeParser;
import three.scenes.Scene;
import three.objects.Object3D;

#if webgpu
import three.renderers.webgpu.WebGPUShaderStage;
#end

class WGSLNodeBuilder extends NodeBuilder {

	public uniformGroups:Map<String, NodeUniformsGroup> = new Map();
	public builtins:Map<String, Map<String, { name:String, property:String, type:String }>> = new Map();

	public function new( object:Object3D, renderer:Dynamic, scene:Scene = null ) {
		super( object, renderer, new WGSLNodeParser(), scene );
	}

	override public function needsColorSpaceToLinear( texture:Texture ):Bool {
		return texture.isVideoTexture && texture.colorSpace != NoColorSpace;
	}

	override public function _generateTextureSample( texture:Texture, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			if ( depthSnippet != null ) {
				return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${depthSnippet})';
			} else {
				return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet})';
			}
		} else {
			return this.generateTextureLod( texture, textureProperty, uvSnippet );
		}
	}

	override public function _generateVideoSample( textureProperty:String, uvSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			return 'textureSampleBaseClampToEdge(${textureProperty}, ${textureProperty}_sampler, vec2<f32>(${uvSnippet}.x, 1.0 - ${uvSnippet}.y))';
		} else {
			throw "WebGPURenderer: THREE.VideoTexture does not support ${shaderStage} shader.";
		}
	}

	override public function _generateTextureSampleLevel( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" && this.isUnfilterable( texture ) == false ) {
			return 'textureSampleLevel(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${levelSnippet})';
		} else {
			return this.generateTextureLod( texture, textureProperty, uvSnippet, levelSnippet );
		}
	}

	public function generateTextureLod( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String = "0" ):String {
		this._include( "repeatWrapping" );
		var dimension = 'textureDimensions(${textureProperty}, 0)';
		return 'textureLoad(${textureProperty}, threejs_repeatWrapping(${uvSnippet}, ${dimension}), i32(${levelSnippet}))';
	}

	public function generateTextureLoad( texture:Texture, textureProperty:String, uvIndexSnippet:String, depthSnippet:String, levelSnippet:String = "0u" ):String {
		if ( depthSnippet != null ) {
			return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${depthSnippet}, ${levelSnippet})';
		} else {
			return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${levelSnippet})';
		}
	}

	public function generateTextureStore( texture:Texture, textureProperty:String, uvIndexSnippet:String, valueSnippet:String ):String {
		return 'textureStore(${textureProperty}, ${uvIndexSnippet}, ${valueSnippet})';
	}

	public function isUnfilterable( texture:Texture ):Bool {
		return this.getComponentTypeFromTexture( texture ) != "float" || ( texture.isDataTexture && texture.type == FloatType );
	}

	override public function generateTexture( texture:Texture, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		var snippet:String;

		if ( texture.isVideoTexture ) {
			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );
		} else if ( this.isUnfilterable( texture ) ) {
			snippet = this.generateTextureLod( texture, textureProperty, uvSnippet, "0", depthSnippet, shaderStage );
		} else {
			snippet = this._generateTextureSample( texture, textureProperty, uvSnippet, depthSnippet, shaderStage );
		}

		return snippet;
	}

	override public function generateTextureGrad( texture:Texture, textureProperty:String, uvSnippet:String, gradSnippet:Array<String>, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			// TODO handle i32 or u32 --> uvSnippet, array_index: A, ddx, ddy
			return 'textureSampleGrad(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${gradSnippet[0]}, ${gradSnippet[1]})';
		} else {
			throw "WebGPURenderer: THREE.TextureNode.gradient() does not support ${shaderStage} shader.";
		}
	}

	override public function generateTextureCompare( texture:Texture, textureProperty:String, uvSnippet:String, compareSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			return 'textureSampleCompare(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${compareSnippet})';
		} else {
			throw "WebGPURenderer: THREE.DepthTexture.compareFunction() does not support ${shaderStage} shader.";
		}
	}

	override public function generateTextureLevel( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		var snippet:String;

		if ( texture.isVideoTexture ) {
			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );
		} else {
			snippet = this._generateTextureSampleLevel( texture, textureProperty, uvSnippet, levelSnippet, depthSnippet, shaderStage );
		}

		return snippet;
	}

	override public function getPropertyName( node:Node, shaderStage:String = this.shaderStage ):String {
		if ( node.isNodeVarying && node.needsInterpolation ) {
			if ( shaderStage == "vertex" ) {
				return 'varyings.${node.name}';
			}
		} else if ( node.isNodeUniform ) {
			var name = node.name;
			var type = node.type;

			if ( type == "texture" || type == "cubeTexture" || type == "storageTexture" ) {
				return name;
			} else if ( type == "buffer" || type == "storageBuffer" ) {
				return 'NodeBuffer_${node.id}.${name}';
			} else {
				return node.groupNode.name + '.' + name;
			}
		}

		return super.getPropertyName( node );
	}

	public function _getUniformGroupCount( shaderStage:String ):Int {
		return this.uniforms[shaderStage].keys().length;
	}

	override public function getFunctionOperator( op:String ):String {
		var fnOp = wgslFnOpLib[op];

		if ( fnOp != null ) {
			this._include( fnOp );
			return fnOp;
		}

		return null;
	}

	override public function getUniformFromNode( node:Node, type:String, shaderStage:String, name:String = null ):{ name:String, node:Node } {
		var uniformNode = super.getUniformFromNode( node, type, shaderStage, name );
		var nodeData = this.getDataFromNode( node, shaderStage, this.globalCache );

		if ( nodeData.uniformGPU == null ) {
			var uniformGPU:Dynamic;
			var bindings = this.bindings[shaderStage];

			if ( type == "texture" || type == "cubeTexture" || type == "storageTexture" ) {
				var texture:Dynamic;

				if ( type == "texture" || type == "storageTexture" ) {
					texture = new NodeSampledTexture( uniformNode.name, uniformNode.node );
				} else if ( type == "cubeTexture" ) {
					texture = new NodeSampledCubeTexture( uniformNode.name, uniformNode.node );
				}

				texture.store = node.isStoreTextureNode;
				texture.setVisibility( gpuShaderStageLib[shaderStage] );

				if ( shaderStage == "fragment" && this.isUnfilterable( node.value ) == false && texture.store == false ) {
					var sampler = new NodeSampler( '${uniformNode.name}_sampler', uniformNode.node );
					sampler.setVisibility( gpuShaderStageLib[shaderStage] );

					bindings.push( sampler, texture );

					uniformGPU = [sampler, texture];
				} else {
					bindings.push( texture );

					uniformGPU = [texture];
				}
			} else if ( type == "buffer" || type == "storageBuffer" ) {
				var bufferClass:Class<Dynamic> = type == "storageBuffer" ? NodeStorageBuffer : NodeUniformBuffer;
				var buffer = new bufferClass( node );
				buffer.setVisibility( gpuShaderStageLib[shaderStage] );

				bindings.push( buffer );

				uniformGPU = buffer;
			} else {
				var group = node.groupNode;
				var groupName = group.name;

				var uniformsStage = this.uniformGroups.get( shaderStage );
				if ( uniformsStage == null ) {
					uniformsStage = new Map();
					this.uniformGroups.set( shaderStage, uniformsStage );
				}

				var uniformsGroup = uniformsStage.get( groupName );

				if ( uniformsGroup == null ) {
					uniformsGroup = new NodeUniformsGroup( groupName, group );
					uniformsGroup.setVisibility( gpuShaderStageLib[shaderStage] );

					uniformsStage.set( groupName, uniformsGroup );

					bindings.push( uniformsGroup );
				}

				uniformGPU = this.getNodeUniform( uniformNode, type );

				uniformsGroup.addUniform( uniformGPU );
			}

			nodeData.uniformGPU = uniformGPU;

			if ( shaderStage == "vertex" ) {
				this.bindingsOffset["fragment"] = bindings.length;
			}
		}

		return uniformNode;
	}

	override public function isReference( type:String ):Bool {
		return super.isReference( type ) || type == "texture_2d" || type == "texture_cube" || type == "texture_depth_2d" || type == "texture_storage_2d";
	}

	public function getBuiltin( name:String, property:String, type:String, shaderStage:String = this.shaderStage ):String {
		var map = this.builtins.get( shaderStage );
		if ( map == null ) {
			map = new Map();
			this.builtins.set( shaderStage, map );
		}

		if ( !map.exists( name ) ) {
			map.set( name, { name:name, property:property, type:type } );
		}

		return property;
	}

	override public function getVertexIndex():String {
		if ( this.shaderStage == "vertex" ) {
			return this.getBuiltin( "vertex_index", "vertexIndex", "u32", "attribute" );
		}

		return "vertexIndex";
	}

	override public function buildFunctionCode( shaderNode:NodeFunction ):String {
		var layout = shaderNode.layout;
		var flowData = this.flowShaderNode( shaderNode );

		var parameters:Array<String> = [];

		for ( input in layout.inputs ) {
			parameters.push( input.name + ' : ' + this.getType( input.type ) );
		}

		//

		var code = 'fn ${layout.name}(${parameters.join(", ")}) -> ${this.getType( layout.type )} {\n${flowData.vars}\n${flowData.code}\n\treturn ${flowData.result};\n\n}';

		//

		return code;
	}

	override public function getInstanceIndex():String {
		if ( this.shaderStage == "vertex" ) {
			return this.getBuiltin( "instance_index", "instanceIndex", "u32", "attribute" );
		}

		return "instanceIndex";
	}

	override public function getFrontFacing():String {
		return this.getBuiltin( "front_facing", "isFront", "bool" );
	}

	override public function getFragCoord():String {
		return '${this.getBuiltin( "position", "fragCoord", "vec4<f32>" )}.xyz';
	}

	override public function getFragDepth():String {
		return 'output.${this.getBuiltin( "frag_depth", "depth", "f32", "output" )}';
	}

	override public function isFlipY():Bool {
		return false;
	}

	public function getBuiltins( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var builtins = this.builtins.get( shaderStage );

		if ( builtins != null ) {
			for ( builtin in builtins.values() ) {
				snippets.push( `@builtin(${builtin.name}) ${builtin.property} : ${builtin.type}` );
			}
		}

		return snippets.join( ',\n\t' );
	}

	public function getAttributes( shaderStage:String ):String {
		var snippets:Array<String> = [];

		if ( shaderStage == "compute" ) {
			this.getBuiltin( "global_invocation_id", "id", "vec3<u32>", "attribute" );
		}

		if ( shaderStage == "vertex" || shaderStage == "compute" ) {
			var builtins = this.getBuiltins( "attribute" );

			if ( builtins != null ) snippets.push( builtins );

			var attributes = this.getAttributesArray();

			for ( i in 0...attributes.length ) {
				var attribute = attributes[i];
				var name = attribute.name;
				var type = this.getType( attribute.type );

				snippets.push( `@location(${i}) ${name} : ${type}` );
			}
		}

		return snippets.join( ',\n\t' );
	}

	public function getStructMembers( struct:NodeStruct ):String {
		var snippets:Array<String> = [];
		var members = struct.getMemberTypes();

		for ( i in 0...members.length ) {
			var member = members[i];
			snippets.push( `\t@location(${i}) m${i} : ${member}<f32>` );
		}

		return snippets.join( ',\n' );
	}

	public function getStructs( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var structs = this.structs[shaderStage];

		for ( i in 0...structs.length ) {
			var struct = structs[i];
			var name = struct.name;

			var snippet = `\struct ${name} {\n`;
			snippet += this.getStructMembers( struct );
			snippet += '\n}';

			snippets.push( snippet );
		}

		return snippets.join( '\n\n' );
	}

	public function getVar( type:String, name:String ):String {
		return 'var ${name} : ${this.getType( type )}';
	}

	public function getVars( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var vars = this.vars[shaderStage];

		if ( vars != null ) {
			for ( variable in vars ) {
				snippets.push( `\t${this.getVar( variable.type, variable.name )};` );
			}
		}

		return `\n${snippets.join( '\n' )}\n`;
	}

	public function getVaryings( shaderStage:String ):String {
		var snippets:Array<String> = [];

		if ( shaderStage == "vertex" ) {
			this.getBuiltin( "position", "Vertex", "vec4<f32>", "vertex" );
		}

		if ( shaderStage == "vertex" || shaderStage == "fragment" ) {
			var varyings = this.varyings;
			var vars = this.vars[shaderStage];

			for ( i in 0...varyings.length ) {
				var varying = varyings[i];

				if ( varying.needsInterpolation ) {
					var attributesSnippet = `@location(${i})`;

					if ( Type.regex( varying.type, "^(int|uint|ivec|uvec)" ) ) {
						attributesSnippet += ' @interpolate( flat )';
					}

					snippets.push( `${attributesSnippet} ${varying.name} : ${this.getType( varying.type )}` );
				} else if ( shaderStage == "vertex" && !vars.contains( varying ) ) {
					vars.push( varying );
				}
			}
		}

		var builtins = this.getBuiltins( shaderStage );

		if ( builtins != null ) snippets.push( builtins );

		var code = snippets.join( ',\n\t' );

		return shaderStage == "vertex" ? this._getWGSLStruct( "VaryingsStruct", '\t' + code ) : code;
	}

	public function getUniforms( shaderStage:String ):String {
		var uniforms = this.uniforms[shaderStage];

		var bindingSnippets:Array<String> = [];
		var bufferSnippets:Array<String> = [];
		var structSnippets:Array<String> = [];
		var uniformGroups:Map<String, { index:Int, snippets:Array<String> }> = new Map();

		var index = this.bindingsOffset[shaderStage];

		for ( uniform in uniforms ) {
			if ( uniform.type == "texture" || uniform.type == "cubeTexture" || uniform.type == "storageTexture" ) {
				var texture = uniform.node.value;

				if ( shaderStage == "fragment" && this.isUnfilterable( texture ) == false && uniform.node.isStoreTextureNode == false ) {
					if ( texture.isDepthTexture && texture.compareFunction != null ) {
						bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name}_sampler : sampler_comparison;` );
					} else {
						bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name}_sampler : sampler;` );
					}
				}

				var textureType:String;

				if ( texture.isCubeTexture ) {
					textureType = "texture_cube<f32>";
				} else if ( texture.isDataArrayTexture ) {
					textureType = "texture_2d_array<f32>";
				} else if ( texture.isDepthTexture ) {
					textureType = "texture_depth_2d";
				} else if ( texture.isVideoTexture ) {
					textureType = "texture_external";
				} else if ( uniform.node.isStoreTextureNode ) {
					var format = WebGPUTextureUtils.getFormat( texture );
					textureType = `texture_storage_2d<${format}, write>`;
				} else {
					var componentPrefix = this.getComponentTypeFromTexture( texture ).charAt( 0 );
					textureType = `texture_2d<${componentPrefix}32>`;
				}

				bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name} : ${textureType};` );
			} else if ( uniform.type == "buffer" || uniform.type == "storageBuffer" ) {
				var bufferNode = uniform.node;
				var bufferType = this.getType( bufferNode.bufferType );
				var bufferCount = bufferNode.bufferCount;

				var bufferCountSnippet = bufferCount > 0 ? ', ' + bufferCount : '';
				var bufferSnippet = `\t${uniform.name} : array< ${bufferType}${bufferCountSnippet} >\n`;
				var bufferAccessMode = bufferNode.isStorageBufferNode ? "storage,read_write" : "uniform";

				bufferSnippets.push( this._getWGSLStructBinding( "NodeBuffer_" + bufferNode.id, bufferSnippet, bufferAccessMode, index++ ) );
			} else {
				var vectorType = this.getType( this.getVectorType( uniform.type ) );
				var groupName = uniform.groupNode.name;

				var group = uniformGroups.get( groupName );
				if ( group == null ) {
					group = { index:index++, snippets:[] };
					uniformGroups.set( groupName, group );
				}

				group.snippets.push( `\t${uniform.name} : ${vectorType}` );
			}
		}

		for ( name in uniformGroups.keys() ) {
			var group = uniformGroups.get( name );

			structSnippets.push( this._getWGSLStructBinding( name, group.snippets.join( ',\n' ), "uniform", group.index ) );
		}

		var code = bindingSnippets.join( '\n' );
		code += bufferSnippets.join( '\n' );
		code += structSnippets.join( '\n' );

		return code;
	}

	override public function buildCode() {
		var shadersData = this.material != null ? { fragment: {}, vertex: {} } : { compute: {} };

		for ( shaderStage in shadersData.keys() ) {
			var stageData = shadersData[shaderStage];
			stageData.uniforms = this.getUniforms( shaderStage );
			stageData.attributes = this.getAttributes( shaderStage );
			stageData.varyings = this.getVaryings( shaderStage );
			stageData.structs = this.getStructs( shaderStage );
			stageData.vars = this.getVars( shaderStage );
			stageData.codes = this.getCodes( shaderStage );

			//

			var flow = '// code\n\n';
			flow += this.flowCode[shaderStage];

			var flowNodes = this.flowNodes[shaderStage];
			var mainNode = flowNodes[flowNodes.length - 1];

			var outputNode = mainNode.outputNode;
			var isOutputStruct = ( outputNode != null && outputNode.isOutputStructNode );

			for ( node in flowNodes ) {
				var flowSlotData = this.getFlowData( node );
				var slotName = node.name;

				if ( slotName != null ) {
					if ( flow.length > 0 ) flow += '\n';
					flow += `\t// flow -> ${slotName}\n\t`;
				}

				flow += `${flowSlotData.code}\n\t`;

				if ( node == mainNode && shaderStage != "compute" ) {
					flow += '// result\n\n\t';

					if ( shaderStage == "vertex" ) {
						flow += `varyings.Vertex = ${flowSlotData.result};`;
					} else if ( shaderStage == "fragment" ) {
						if ( isOutputStruct ) {
							stageData.returnType = outputNode.nodeType;
							flow += `return ${flowSlotData.result};`;
						} else {
							var structSnippet = '\t@location(0) color: vec4<f32>';

							var builtins = this.getBuiltins( "output" );

							if ( builtins != null ) structSnippet += ',\n\t' + builtins;

							stageData.returnType = "OutputStruct";
							stageData.structs += this._getWGSLStruct( "OutputStruct", structSnippet );
							stageData.structs += '\nvar<private> output : OutputStruct;\n\n';

							flow += `output.color = ${flowSlotData.result};\n\n\treturn output;`;
						}
					}
				}
			}

			stageData.flow = flow;
		}

		if ( this.material != null ) {
			this.vertexShader = this._getWGSLVertexCode( shadersData.vertex );
			this.fragmentShader = this._getWGSLFragmentCode( shadersData.fragment );
		} else {
			this.computeShader = this._getWGSLComputeCode( shadersData.compute, ( this.object.workgroupSize != null ? this.object.workgroupSize : [64] ).join( ", " ) );
		}
	}

	override public function getMethod( method:String, output:String = null ):String {
		var wgslMethod:String;

		if ( output != null ) {
			wgslMethod = this._getWGSLMethod( method + '_' + output );
		}

		if ( wgslMethod == null ) {
			wgslMethod = this._getWGSLMethod( method );
		}

		return wgslMethod != null ? wgslMethod : method;
	}

	override public function getType( type:String ):String {
		return wgslTypeLib[type] != null ? wgslTypeLib[type] : type;
	}

	override public function isAvailable( name:String ):Bool {
		return supports[name];
	}

	public function _getWGSLMethod( method:String ):String {
		if ( wgslPolyfill[method] != null ) {
			this._include( method );
		}

		return wgslMethods[method];
	}

	public function _include( name:String ):CodeNode {
		var codeNode = wgslPolyfill[name];
		codeNode.build( this );

		if ( this.currentFunctionNode != null ) {
			this.currentFunctionNode.includes.push( codeNode );
		}

		return codeNode;
	}

	public function _getWGSLVertexCode( shaderData:Dynamic ):String {
		return `${this.getSignature()}

// uniforms
${shaderData.uniforms}

// varyings
${shaderData.varyings}
var<private> varyings : VaryingsStruct;

// codes
${shaderData.codes}

@vertex
fn main(${shaderData.attributes}) -> VaryingsStruct {

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

	return varyings;

}
`;
	}

	public function _getWGSLFragmentCode( shaderData:Dynamic ):String {
		return `${this.getSignature()}

// uniforms
${shaderData.uniforms}

// structs
${shaderData.structs}

// codes
${shaderData.codes}

@fragment
fn main(${shaderData.varyings}) -> ${shaderData.returnType} {

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

}
`;
	}

	public function _getWGSLComputeCode( shaderData:Dynamic, workgroupSize:String ):String {
		return `${this.getSignature()}
// system
var<private> instanceIndex : u32;

// uniforms
${shaderData.uniforms}

// codes
${shaderData.codes}

@compute @workgroup_size(${workgroupSize})
fn main(${shaderData.attributes}) {

	// system
	instanceIndex = id.x;

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

}
`;
	}

	public function _getWGSLStruct( name:String, vars:String ):String {
		return `
struct ${name} {
${vars}
};`;
	}

	public function _getWGSLStructBinding( name:String, vars:String, access:String, binding:Int = 0, group:Int = 0 ):String {
		var structName = name + "Struct";
		var structSnippet = this._getWGSLStruct( structName, vars );

		return `${structSnippet}
@binding(${binding}) @group(${group})
var<${access}> ${name} : ${structName};`;
	}

}

// GPUShaderStage is not defined in browsers not supporting WebGPU
#if webgpu
var GPUShaderStage = WebGPUShaderStage;
#end

var gpuShaderStageLib:Map<String, Int> = {
	"vertex": GPUShaderStage != null ? GPUShaderStage.VERTEX : 1,
	"fragment": GPUShaderStage != null ? GPUShaderStage.FRAGMENT : 2,
	"compute": GPUShaderStage != null ? GPUShaderStage.COMPUTE : 4
};

var supports:Map<String, Bool> = {
	"instance": true,
	"storageBuffer": true
};

var wgslFnOpLib:Map<String, String> = {
	"^^": "threejs_xor"
};

var wgslTypeLib:Map<String, String> = {
	"float": "f32",
	"int": "i32",
	"uint": "u32",
	"bool": "bool",
	"color": "vec3<f32>",

	"vec2": "vec2<f32>",
	"ivec2": "vec2<i32>",
	"uvec2": "vec2<u32>",
	"bvec2": "vec2<bool>",

	"vec3": "vec3<f32>",
	"ivec3": "vec3<i32>",
	"uvec3": "vec3<u32>",
	"bvec3": "vec3<bool>",

	"vec4": "vec4<f32>",
	"ivec4": "vec4<i32>",
	"uvec4": "vec4<u32>",
	"bvec4": "vec4<bool>",

	"mat2": "mat2x2<f32>",
	"imat2": "mat2x2<i32>",
	"umat2": "mat2x2<u32>",
	"bmat2": "mat2x2<bool>",

	"mat3": "mat3x3<f32>",
	"imat3": "mat3x3<i32>",
	"umat3": "mat3x3<u32>",
	"bmat3": "mat3x3<bool>",

	"mat4": "mat4x4<f32>",
	"imat4": "mat4x4<i32>",
	"umat4": "mat4x4<u32>",
	"bmat4": "mat4x4<bool>"
};

var wgslMethods:Map<String, String> = {
	"dFdx": "dpdx",
	"dFdy": "- dpdy",
	"mod_float": "threejs_mod_float",
	"mod_vec2": "threejs_mod_vec2",
	"mod_vec3": "threejs_mod_vec3",
	"mod_vec4": "threejs_mod_vec4",
	"equals_bool": "threejs_equals_bool",
	"equals_bvec2": "threejs_equals_bvec2",
	"equals_bvec3": "threejs_equals_bvec3",
	"equals_bvec4": "threejs_equals_bvec4",
	"lessThanEqual": "threejs_lessThanEqual",
	"greaterThan": "threejs_greaterThan",
	"inversesqrt": "inverseSqrt",
	"bitcast": "bitcast<f32>"
};

var wgslPolyfill:Map<String, CodeNode> = {
	"threejs_xor": new CodeNode( `
fn threejs_xor( a : bool, b : bool ) -> bool {

	return ( a || b ) && !( a && b );

}
` ),
	"lessThanEqual": new CodeNode( `
fn threejs_lessThanEqual( a : vec3<f32>, b : vec3<f32> ) -> vec3<bool> {
var wgslPolyfill:Map<String, CodeNode> = {
	"threejs_xor": new CodeNode( `
fn threejs_xor( a : bool, b : bool ) -> bool {

	return ( a || b ) && !( a && b );

}
` ),
	"lessThanEqual": new CodeNode( `
fn threejs_lessThanEqual( a : vec3<f32>, b : vec3<f32> ) -> vec3<bool> {

	return vec3<bool>( a.x <= b.x, a.y <= b.y, a.z <= b.z );

}
` ),
	"greaterThan": new CodeNode( `
fn threejs_greaterThan( a : vec3<f32>, b : vec3<f32> ) -> vec3<bool> {

	return vec3<bool>( a.x > b.x, a.y > b.y, a.z > b.z );

}
` ),
	"mod_float": new CodeNode( 'fn threejs_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }' ),
	"mod_vec2": new CodeNode( 'fn threejs_mod_vec2( x : vec2f, y : vec2f ) -> vec2f { return x - y * floor( x / y ); }' ),
	"mod_vec3": new CodeNode( 'fn threejs_mod_vec3( x : vec3f, y : vec3f ) -> vec3f { return x - y * floor( x / y ); }' ),
	"mod_vec4": new CodeNode( 'fn threejs_mod_vec4( x : vec4f, y : vec4f ) -> vec4f { return x - y * floor( x / y ); }' ),
	"equals_bool": new CodeNode( 'fn threejs_equals_bool( a : bool, b : bool ) -> bool { return a == b; }' ),
	"equals_bvec2": new CodeNode( 'fn threejs_equals_bvec2( a : vec2f, b : vec2f ) -> vec2<bool> { return vec2<bool>( a.x == b.x, a.y == b.y ); }' ),
	"equals_bvec3": new CodeNode( 'fn threejs_equals_bvec3( a : vec3f, b : vec3f ) -> vec3<bool> { return vec3<bool>( a.x == b.x, a.y == b.y, a.z == b.z ); }' ),
	"equals_bvec4": new CodeNode( 'fn threejs_equals_bvec4( a : vec4f, b : vec4f ) -> vec4<bool> { return vec4<bool>( a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w ); }' ),
	"repeatWrapping": new CodeNode( `
fn threejs_repeatWrapping( uv : vec2<f32>, dimension : vec2<u32> ) -> vec2<u32> {

	let uvScaled = vec2<u32>( uv * vec2<f32>( dimension ) );

	return ( ( uvScaled % dimension ) + dimension ) % dimension;

}
` )
};

class WGSLNodeBuilder extends NodeBuilder {

	public uniformGroups:Map<String, NodeUniformsGroup> = new Map();
	public builtins:Map<String, Map<String, { name:String, property:String, type:String }>> = new Map();

	public function new( object:Object3D, renderer:Dynamic, scene:Scene = null ) {
		super( object, renderer, new WGSLNodeParser(), scene );
	}

	override public function needsColorSpaceToLinear( texture:Texture ):Bool {
		return texture.isVideoTexture && texture.colorSpace != NoColorSpace;
	}

	override public function _generateTextureSample( texture:Texture, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			if ( depthSnippet != null ) {
				return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${depthSnippet})';
			} else {
				return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet})';
			}
		} else {
			return this.generateTextureLod( texture, textureProperty, uvSnippet );
		}
	}

	override public function _generateVideoSample( textureProperty:String, uvSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			return 'textureSampleBaseClampToEdge(${textureProperty}, ${textureProperty}_sampler, vec2<f32>(${uvSnippet}.x, 1.0 - ${uvSnippet}.y))';
		} else {
			throw "WebGPURenderer: THREE.VideoTexture does not support ${shaderStage} shader.";
		}
	}

	override public function _generateTextureSampleLevel( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" && this.isUnfilterable( texture ) == false ) {
			return 'textureSampleLevel(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${levelSnippet})';
		} else {
			return this.generateTextureLod( texture, textureProperty, uvSnippet, levelSnippet );
		}
	}

	public function generateTextureLod( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String = "0" ):String {
		this._include( "repeatWrapping" );
		var dimension = 'textureDimensions(${textureProperty}, 0)';
		return 'textureLoad(${textureProperty}, threejs_repeatWrapping(${uvSnippet}, ${dimension}), i32(${levelSnippet}))';
	}

	public function generateTextureLoad( texture:Texture, textureProperty:String, uvIndexSnippet:String, depthSnippet:String, levelSnippet:String = "0u" ):String {
		if ( depthSnippet != null ) {
			return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${depthSnippet}, ${levelSnippet})';
		} else {
			return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${levelSnippet})';
		}
	}

	public function generateTextureStore( texture:Texture, textureProperty:String, uvIndexSnippet:String, valueSnippet:String ):String {
		return 'textureStore(${textureProperty}, ${uvIndexSnippet}, ${valueSnippet})';
	}

	public function isUnfilterable( texture:Texture ):Bool {
		return this.getComponentTypeFromTexture( texture ) != "float" || ( texture.isDataTexture && texture.type == FloatType );
	}

	override public function generateTexture( texture:Texture, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		var snippet:String;

		if ( texture.isVideoTexture ) {
			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );
		} else if ( this.isUnfilterable( texture ) ) {
			snippet = this.generateTextureLod( texture, textureProperty, uvSnippet, "0", depthSnippet, shaderStage );
		} else {
			snippet = this._generateTextureSample( texture, textureProperty, uvSnippet, depthSnippet, shaderStage );
		}

		return snippet;
	}

	override public function generateTextureGrad( texture:Texture, textureProperty:String, uvSnippet:String, gradSnippet:Array<String>, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			// TODO handle i32 or u32 --> uvSnippet, array_index: A, ddx, ddy
			return 'textureSampleGrad(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${gradSnippet[0]}, ${gradSnippet[1]})';
		} else {
			throw "WebGPURenderer: THREE.TextureNode.gradient() does not support ${shaderStage} shader.";
		}
	}

	override public function generateTextureCompare( texture:Texture, textureProperty:String, uvSnippet:String, compareSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			return 'textureSampleCompare(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${compareSnippet})';
		} else {
			throw "WebGPURenderer: THREE.DepthTexture.compareFunction() does not support ${shaderStage} shader.";
		}
	}

	override public function generateTextureLevel( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		var snippet:String;

		if ( texture.isVideoTexture ) {
			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );
		} else {
			snippet = this._generateTextureSampleLevel( texture, textureProperty, uvSnippet, levelSnippet, depthSnippet, shaderStage );
		}

		return snippet;
	}

	override public function getPropertyName( node:Node, shaderStage:String = this.shaderStage ):String {
		if ( node.isNodeVarying && node.needsInterpolation ) {
			if ( shaderStage == "vertex" ) {
				return 'varyings.${node.name}';
			}
		} else if ( node.isNodeUniform ) {
			var name = node.name;
			var type = node.type;

			if ( type == "texture" || type == "cubeTexture" || type == "storageTexture" ) {
				return name;
			} else if ( type == "buffer" || type == "storageBuffer" ) {
				return 'NodeBuffer_${node.id}.${name}';
			} else {
				return node.groupNode.name + '.' + name;
			}
		}

		return super.getPropertyName( node );
	}

	public function _getUniformGroupCount( shaderStage:String ):Int {
		return this.uniforms[shaderStage].keys().length;
	}

	override public function getFunctionOperator( op:String ):String {
		var fnOp = wgslFnOpLib[op];

		if ( fnOp != null ) {
			this._include( fnOp );
			return fnOp;
		}

		return null;
	}

	override public function getUniformFromNode( node:Node, type:String, shaderStage:String, name:String = null ):{ name:String, node:Node } {
		var uniformNode = super.getUniformFromNode( node, type, shaderStage, name );
		var nodeData = this.getDataFromNode( node, shaderStage, this.globalCache );

		if ( nodeData.uniformGPU == null ) {
			var uniformGPU:Dynamic;
			var bindings = this.bindings[shaderStage];

			if ( type == "texture" || type == "cubeTexture" || type == "storageTexture" ) {
				var texture:Dynamic;

				if ( type == "texture" || type == "storageTexture" ) {
					texture = new NodeSampledTexture( uniformNode.name, uniformNode.node );
				} else if ( type == "cubeTexture" ) {
					texture = new NodeSampledCubeTexture( uniformNode.name, uniformNode.node );
				}

				texture.store = node.isStoreTextureNode;
				texture.setVisibility( gpuShaderStageLib[shaderStage] );

				if ( shaderStage == "fragment" && this.isUnfilterable( node.value ) == false && texture.store == false ) {
					var sampler = new NodeSampler( '${uniformNode.name}_sampler', uniformNode.node );
					sampler.setVisibility( gpuShaderStageLib[shaderStage] );

					bindings.push( sampler, texture );

					uniformGPU = [sampler, texture];
				} else {
					bindings.push( texture );

					uniformGPU = [texture];
				}
			} else if ( type == "buffer" || type == "storageBuffer" ) {
				var bufferClass:Class<Dynamic> = type == "storageBuffer" ? NodeStorageBuffer : NodeUniformBuffer;
				var buffer = new bufferClass( node );
				buffer.setVisibility( gpuShaderStageLib[shaderStage] );

				bindings.push( buffer );

				uniformGPU = buffer;
			} else {
				var group = node.groupNode;
				var groupName = group.name;

				var uniformsStage = this.uniformGroups.get( shaderStage );
				if ( uniformsStage == null ) {
					uniformsStage = new Map();
					this.uniformGroups.set( shaderStage, uniformsStage );
				}

				var uniformsGroup = uniformsStage.get( groupName );

				if ( uniformsGroup == null ) {
					uniformsGroup = new NodeUniformsGroup( groupName, group );
					uniformsGroup.setVisibility( gpuShaderStageLib[shaderStage] );

					uniformsStage.set( groupName, uniformsGroup );

					bindings.push( uniformsGroup );
				}

				uniformGPU = this.getNodeUniform( uniformNode, type );

				uniformsGroup.addUniform( uniformGPU );
			}

			nodeData.uniformGPU = uniformGPU;

			if ( shaderStage == "vertex" ) {
				this.bindingsOffset["fragment"] = bindings.length;
			}
		}

		return uniformNode;
	}

	override public function isReference( type:String ):Bool {
		return super.isReference( type ) || type == "texture_2d" || type == "texture_cube" || type == "texture_depth_2d" || type == "texture_storage_2d";
	}

	public function getBuiltin( name:String, property:String, type:String, shaderStage:String = this.shaderStage ):String {
		var map = this.builtins.get( shaderStage );
		if ( map == null ) {
			map = new Map();
			this.builtins.set( shaderStage, map );
		}

		if ( !map.exists( name ) ) {
			map.set( name, { name:name, property:property, type:type } );
		}

		return property;
	}

	override public function getVertexIndex():String {
		if ( this.shaderStage == "vertex" ) {
			return this.getBuiltin( "vertex_index", "vertexIndex", "u32", "attribute" );
		}

		return "vertexIndex";
	}

	override public function buildFunctionCode( shaderNode:NodeFunction ):String {
		var layout = shaderNode.layout;
		var flowData = this.flowShaderNode( shaderNode );

		var parameters:Array<String> = [];

		for ( input in layout.inputs ) {
			parameters.push( input.name + ' : ' + this.getType( input.type ) );
		}

		//

		var code = 'fn ${layout.name}(${parameters.join(", ")}) -> ${this.getType( layout.type )} {\n${flowData.vars}\n${flowData.code}\n\treturn ${flowData.result};\n\n}';

		//

		return code;
	}

	override public function getInstanceIndex():String {
		if ( this.shaderStage == "vertex" ) {
			return this.getBuiltin( "instance_index", "instanceIndex", "u32", "attribute" );
		}

		return "instanceIndex";
	}

	override public function getFrontFacing():String {
		return this.getBuiltin( "front_facing", "isFront", "bool" );
	}

	override public function getFragCoord():String {
		return '${this.getBuiltin( "position", "fragCoord", "vec4<f32>" )}.xyz';
	}

	override public function getFragDepth():String {
		return 'output.${this.getBuiltin( "frag_depth", "depth", "f32", "output" )}';
	}

	override public function isFlipY():Bool {
		return false;
	}

	public function getBuiltins( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var builtins = this.builtins.get( shaderStage );

		if ( builtins != null ) {
			for ( builtin in builtins.values() ) {
				snippets.push( `@builtin(${builtin.name}) ${builtin.property} : ${builtin.type}` );
			}
		}

		return snippets.join( ',\n\t' );
	}

	public function getAttributes( shaderStage:String ):String {
		var snippets:Array<String> = [];

		if ( shaderStage == "compute" ) {
			this.getBuiltin( "global_invocation_id", "id", "vec3<u32>", "attribute" );
		}

		if ( shaderStage == "vertex" || shaderStage == "compute" ) {
			var builtins = this.getBuiltins( "attribute" );

			if ( builtins != null ) snippets.push( builtins );

			var attributes = this.getAttributesArray();

			for ( i in 0...attributes.length ) {
				var attribute = attributes[i];
				var name = attribute.name;
				var type = this.getType( attribute.type );

				snippets.push( `@location(${i}) ${name} : ${type}` );
			}
		}

		return snippets.join( ',\n\t' );
	}

	public function getStructMembers( struct:NodeStruct ):String {
		var snippets:Array<String> = [];
		var members = struct.getMemberTypes();

		for ( i in 0...members.length ) {
			var member = members[i];
			snippets.push( `\t@location(${i}) m${i} : ${member}<f32>` );
		}

		return snippets.join( ',\n' );
	}

	public function getStructs( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var structs = this.structs[shaderStage];

		for ( i in 0...structs.length ) {
			var struct = structs[i];
			var name = struct.name;

			var snippet = `\struct ${name} {\n`;
			snippet += this.getStructMembers( struct );
			snippet += '\n}';

			snippets.push( snippet );
		}

		return snippets.join( '\n\n' );
	}

	public function getVar( type:String, name:String ):String {
		return 'var ${name} : ${this.getType( type )}';
	}

	public function getVars( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var vars = this.vars[shaderStage];

		if ( vars != null ) {
			for ( variable in vars ) {
				snippets.push( `\t${this.getVar( variable.type, variable.name )};` );
			}
		}

		return `\n${snippets.join( '\n' )}\n`;
	}

	public function getVaryings( shaderStage:String ):String {
		var snippets:Array<String> = [];

		if ( shaderStage == "vertex" ) {
			this.getBuiltin( "position", "Vertex", "vec4<f32>", "vertex" );
		}

		if ( shaderStage == "vertex" || shaderStage == "fragment" ) {
			var varyings = this.varyings;
			var vars = this.vars[shaderStage];

			for ( i in 0...varyings.length ) {
				var varying = varyings[i];

				if ( varying.needsInterpolation ) {
					var attributesSnippet = `@location(${i})`;

					if ( Type.regex( varying.type, "^(int|uint|ivec|uvec)" ) ) {
						attributesSnippet += ' @interpolate( flat )';
					}

					snippets.push( `${attributesSnippet} ${varying.name} : ${this.getType( varying.type )}` );
				} else if ( shaderStage == "vertex" && !vars.contains( varying ) ) {
					vars.push( varying );
				}
			}
		}

		var builtins = this.getBuiltins( shaderStage );

		if ( builtins != null ) snippets.push( builtins );

		var code = snippets.join( ',\n\t' );

		return shaderStage == "vertex" ? this._getWGSLStruct( "VaryingsStruct", '\t' + code ) : code;
	}

	public function getUniforms( shaderStage:String ):String {
		var uniforms = this.uniforms[shaderStage];

		var bindingSnippets:Array<String> = [];
		var bufferSnippets:Array<String> = [];
		var structSnippets:Array<String> = [];
		var uniformGroups:Map<String, { index:Int, snippets:Array<String> }> = new Map();

		var index = this.bindingsOffset[shaderStage];

		for ( uniform in uniforms ) {
			if ( uniform.type == "texture" || uniform.type == "cubeTexture" || uniform.type == "storageTexture" ) {
				var texture = uniform.node.value;

				if ( shaderStage == "fragment" && this.isUnfilterable( texture ) == false && uniform.node.isStoreTextureNode == false ) {
					if ( texture.isDepthTexture && texture.compareFunction != null ) {
						bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name}_sampler : sampler_comparison;` );
					} else {
						bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name}_sampler : sampler;` );
					}
				}

				var textureType:String;

				if ( texture.isCubeTexture ) {
					textureType = "texture_cube<f32>";
				} else if ( texture.isDataArrayTexture ) {
					textureType = "texture_2d_array<f32>";
				} else if ( texture.isDepthTexture ) {
					textureType = "texture_depth_2d";
				} else if ( texture.isVideoTexture ) {
					textureType = "texture_external";
				} else if ( uniform.node.isStoreTextureNode ) {
					var format = WebGPUTextureUtils.getFormat( texture );
					textureType = `texture_storage_2d<${format}, write>`;
				} else {
					var componentPrefix = this.getComponentTypeFromTexture( texture ).charAt( 0 );
					textureType = `texture_2d<${componentPrefix}32>`;
				}

				bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name} : ${textureType};` );
			} else if ( uniform.type == "buffer" || uniform.type == "storageBuffer" ) {
				var bufferNode = uniform.node;
				var bufferType = this.getType( bufferNode.bufferType );
				var bufferCount = bufferNode.bufferCount;

				var bufferCountSnippet = bufferCount > 0 ? ', ' + bufferCount : '';
				var bufferSnippet = `\t${uniform.name} : array< ${bufferType}${bufferCountSnippet} >\n`;
				var bufferAccessMode = bufferNode.isStorageBufferNode ? "storage,read_write" : "uniform";

				bufferSnippets.push( this._getWGSLStructBinding( "NodeBuffer_" + bufferNode.id, bufferSnippet, bufferAccessMode, index++ ) );
			} else {
				var vectorType = this.getType( this.getVectorType( uniform.type ) );
				var groupName = uniform.groupNode.name;

				var group = uniformGroups.get( groupName );
				if ( group == null ) {
					group = { index:index++, snippets:[] };
					uniformGroups.set( groupName, group );
				}

				group.snippets.push( `\t${uniform.name} : ${vectorType}` );
			}
		}

		for ( name in uniformGroups.keys() ) {
			var group = uniformGroups.get( name );

			structSnippets.push( this._getWGSLStructBinding( name, group.snippets.join( ',\n' ), "uniform", group.index ) );
		}

		var code = bindingSnippets.join( '\n' );
		code += bufferSnippets.join( '\n' );
		code += structSnippets.join( '\n' );

		return code;
	}

	override public function buildCode() {
		var shadersData = this.material != null ? { fragment: {}, vertex: {} } : { compute: {} };

		for ( shaderStage in shadersData.keys() ) {
			var stageData = shadersData[shaderStage];
			stageData.uniforms = this.getUniforms( shaderStage );
			stageData.attributes = this.getAttributes( shaderStage );
			stageData.varyings = this.getVaryings( shaderStage );
			stageData.structs = this.getStructs( shaderStage );
			stageData.vars = this.getVars( shaderStage );
			stageData.codes = this.getCodes( shaderStage );

			//

			var flow = '// code\n\n';
			flow += this.flowCode[shaderStage];

			var flowNodes = this.flowNodes[shaderStage];
			var mainNode = flowNodes[flowNodes.length - 1];

			var outputNode = mainNode.outputNode;
			var isOutputStruct = ( outputNode != null && outputNode.isOutputStructNode );

			for ( node in flowNodes ) {
				var flowSlotData = this.getFlowData( node );
				var slotName = node.name;

				if ( slotName != null ) {
					if ( flow.length > 0 ) flow += '\n';
					flow += `\t// flow -> ${slotName}\n\t`;
				}

				flow += `${flowSlotData.code}\n\t`;

				if ( node == mainNode && shaderStage != "compute" ) {
					flow += '// result\n\n\t';

					if ( shaderStage == "vertex" ) {
						flow += `varyings.Vertex = ${flowSlotData.result};`;
					} else if ( shaderStage == "fragment" ) {
						if ( isOutputStruct ) {
							stageData.returnType = outputNode.nodeType;
							flow += `return ${flowSlotData.result};`;
						} else {
							var structSnippet = '\t@location(0) color: vec4<f32>';

							var builtins = this.getBuiltins( "output" );

							if ( builtins != null ) structSnippet += ',\n\t' + builtins;

							stageData.returnType = "OutputStruct";
							stageData.structs += this._getWGSLStruct( "OutputStruct", structSnippet );
							stageData.structs += '\nvar<private> output : OutputStruct;\n\n';

							flow += `output.color = ${flowSlotData.result};\n\n\treturn output;`;
						}
					}
				}
			}

			stageData.flow = flow;
		}

		if ( this.material != null ) {
			this.vertexShader = this._getWGSLVertexCode( shadersData.vertex );
			this.fragmentShader = this._getWGSLFragmentCode( shadersData.fragment );
		} else {
			this.computeShader = this._getWGSLComputeCode( shadersData.compute, ( this.object.workgroupSize != null ? this.object.workgroupSize : [64] ).join( ", " ) );
		}
	}

	override public function getMethod( method:String, output:String = null ):String {
		var wgslMethod:String;

		if ( output != null ) {
			wgslMethod = this._getWGSLMethod( method + '_' + output );
		}

		if ( wgslMethod == null ) {
			wgslMethod = this._getWGSLMethod( method );
		}

		return wgslMethod != null ? wgslMethod : method;
	}

	override public function getType( type:String ):String {
		return wgslTypeLib[type] != null ? wgslTypeLib[type] : type;
	}

	override public function isAvailable( name:String ):Bool {
		return supports[name];
	}

	public function _getWGSLMethod( method:String ):String {
		if ( wgslPolyfill[method] != null ) {
			this._include( method );
		}

		return wgslMethods[method];
	}

	public function _include( name:String ):CodeNode {
		var codeNode = wgslPolyfill[name];
		codeNode.build( this );

		if ( this.currentFunctionNode != null ) {
			this.currentFunctionNode.includes.push( codeNode );
		}

		return codeNode;
	}

	public function _getWGSLVertexCode( shaderData:Dynamic ):String {
		return `${this.getSignature()}

// uniforms
${shaderData.uniforms}

// varyings
${shaderData.varyings}
var<private> varyings : VaryingsStruct;

// codes
${shaderData.codes}

@vertex
fn main(${shaderData.attributes}) -> VaryingsStruct {

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

	return varyings;

}
`;
	}

	public function _getWGSLFragmentCode( shaderData:Dynamic ):String {
		return `${this.getSignature()}

// uniforms
${shaderData.uniforms}

// structs
${shaderData.structs}

// codes
${shaderData.codes}

@fragment
fn main(${shaderData.varyings}) -> ${shaderData.returnType} {

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

}
`;
	}

	public function _getWGSLComputeCode( shaderData:Dynamic, workgroupSize:String ):String {
		return `${this.getSignature()}
// system
var<private> instanceIndex : u32;

// uniforms
${shaderData.uniforms}

// codes
${shaderData.codes}

@compute @workgroup_size(${workgroupSize})
fn main(${shaderData.attributes}) {

	// system
	instanceIndex = id.x;

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

}
`;
	}

	public function _getWGSLStruct( name:String, vars:String ):String {
		return `
struct ${name} {
${vars}
};`;
	}

	public function _getWGSLStructBinding( name:String, vars:String, access:String, binding:Int = 0, group:Int = 0 ):String {
		var structName = name + "Struct";
		var structSnippet = this._getWGSLStruct( structName, vars );

		return `${structSnippet}
@binding(${binding}) @group(${group})
var<${access}> ${name} : ${structName};`;
	}

}

// GPUShaderStage is not defined in browsers not supporting WebGPU
#if webgpu
var GPUShaderStage = WebGPUShaderStage;
#end

var gpuShaderStageLib:Map<String, Int> = {
	"vertex": GPUShaderStage != null ? GPUShaderStage.VERTEX : 1,
	"fragment": GPUShaderStage != null ? GPUShaderStage.FRAGMENT : 2,
	"compute": GPUShaderStage != null ? GPUShaderStage.COMPUTE : 4
};

var supports:Map<String, Bool> = {
	"instance": true,
	"storageBuffer": true
};

var wgslFnOpLib:Map<String, String> = {
	"^^": "threejs_xor"
};

var wgslTypeLib:Map<String, String> = {
	"float": "f32",
	"int": "i32",
	"uint": "u32",
	"bool": "bool",
	"color": "vec3<f32>",

	"vec2": "vec2<f32>",
	"ivec2": "vec2<i32>",
	"uvec2": "vec2<u32>",
	"bvec2": "vec2<bool>",

	"vec3": "vec3<f32>",
	"ivec3": "vec3<i32>",
	"uvec3": "vec3<u32>",
	"bvec3": "vec3<bool>",

	"vec4": "vec4<f32>",
	"ivec4": "vec4<i32>",
	"uvec4": "vec4<u32>",
	"bvec4": "vec4<bool>",

	"mat2": "mat2x2<f32>",
	"imat2": "mat2x2<i32>",
	"umat2": "mat2x2<u32>",
	"bmat2": "mat2x2<bool>",

	"mat3": "mat3x3<f32>",
	"imat3": "mat3x3<i32>",
	"umat3": "mat3x3<u32>",
	"bmat3": "mat3x3<bool>",

	"mat4": "mat4x4<f32>",
	"imat4": "mat4x4<i32>",
	"umat4": "mat4x4<u32>",
	"bmat4": "mat4x4<bool>"
};

var wgslMethods:Map<String, String> = {
	"dFdx": "dpdx",
	"dFdy": "- dpdy",
	"mod_float": "threejs_mod_float",
	"mod_vec2": "threejs_mod_vec2",
	"mod_vec3": "threejs_mod_vec3",
	"mod_vec4": "threejs_mod_vec4",
	"equals_bool": "threejs_equals_bool",
	"equals_bvec2": "threejs_equals_bvec2",
	"equals_bvec3": "threejs_equals_bvec3",
	"equals_bvec4": "threejs_equals_bvec4",
	"lessThanEqual": "threejs_lessThanEqual",
	"greaterThan": "threejs_greaterThan",
	"inversesqrt": "inverseSqrt",
	"bitcast": "bitcast<f32>"
};

var wgslPolyfill:Map
var wgslPolyfill:Map<String, CodeNode> = {
	"threejs_xor": new CodeNode( `
fn threejs_xor( a : bool, b : bool ) -> bool {

	return ( a || b ) && !( a && b );

}
` ),
	"lessThanEqual": new CodeNode( `
fn threejs_lessThanEqual( a : vec3<f32>, b : vec3<f32> ) -> vec3<bool> {

	return vec3<bool>( a.x <= b.x, a.y <= b.y, a.z <= b.z );

}
` ),
	"greaterThan": new CodeNode( `
fn threejs_greaterThan( a : vec3<f32>, b : vec3<f32> ) -> vec3<bool> {

	return vec3<bool>( a.x > b.x, a.y > b.y, a.z > b.z );

}
` ),
	"mod_float": new CodeNode( 'fn threejs_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }' ),
	"mod_vec2": new CodeNode( 'fn threejs_mod_vec2( x : vec2f, y : vec2f ) -> vec2f { return x - y * floor( x / y ); }' ),
	"mod_vec3": new CodeNode( 'fn threejs_mod_vec3( x : vec3f, y : vec3f ) -> vec3f { return x - y * floor( x / y ); }' ),
	"mod_vec4": new CodeNode( 'fn threejs_mod_vec4( x : vec4f, y : vec4f ) -> vec4f { return x - y * floor( x / y ); }' ),
	"equals_bool": new CodeNode( 'fn threejs_equals_bool( a : bool, b : bool ) -> bool { return a == b; }' ),
	"equals_bvec2": new CodeNode( 'fn threejs_equals_bvec2( a : vec2f, b : vec2f ) -> vec2<bool> { return vec2<bool>( a.x == b.x, a.y == b.y ); }' ),
	"equals_bvec3": new CodeNode( 'fn threejs_equals_bvec3( a : vec3f, b : vec3f ) -> vec3<bool> { return vec3<bool>( a.x == b.x, a.y == b.y, a.z == b.z ); }' ),
	"equals_bvec4": new CodeNode( 'fn threejs_equals_bvec4( a : vec4f, b : vec4f ) -> vec4<bool> { return vec4<bool>( a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w ); }' ),
	"repeatWrapping": new CodeNode( `
fn threejs_repeatWrapping( uv : vec2<f32>, dimension : vec2<u32> ) -> vec2<u32> {

	let uvScaled = vec2<u32>( uv * vec2<f32>( dimension ) );

	return ( ( uvScaled % dimension ) + dimension ) % dimension;

}
` )
};

class WGSLNodeBuilder extends NodeBuilder {

	public uniformGroups:Map<String, NodeUniformsGroup> = new Map();
	public builtins:Map<String, Map<String, { name:String, property:String, type:String }>> = new Map();

	public function new( object:Object3D, renderer:Dynamic, scene:Scene = null ) {
		super( object, renderer, new WGSLNodeParser(), scene );
	}

	override public function needsColorSpaceToLinear( texture:Texture ):Bool {
		return texture.isVideoTexture && texture.colorSpace != NoColorSpace;
	}

	override public function _generateTextureSample( texture:Texture, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			if ( depthSnippet != null ) {
				return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${depthSnippet})';
			} else {
				return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet})';
			}
		} else {
			return this.generateTextureLod( texture, textureProperty, uvSnippet );
		}
	}

	override public function _generateVideoSample( textureProperty:String, uvSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			return 'textureSampleBaseClampToEdge(${textureProperty}, ${textureProperty}_sampler, vec2<f32>(${uvSnippet}.x, 1.0 - ${uvSnippet}.y))';
		} else {
			throw "WebGPURenderer: THREE.VideoTexture does not support ${shaderStage} shader.";
		}
	}

	override public function _generateTextureSampleLevel( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" && this.isUnfilterable( texture ) == false ) {
			return 'textureSampleLevel(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${levelSnippet})';
		} else {
			return this.generateTextureLod( texture, textureProperty, uvSnippet, levelSnippet );
		}
	}

	public function generateTextureLod( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String = "0" ):String {
		this._include( "repeatWrapping" );
		var dimension = 'textureDimensions(${textureProperty}, 0)';
		return 'textureLoad(${textureProperty}, threejs_repeatWrapping(${uvSnippet}, ${dimension}), i32(${levelSnippet}))';
	}

	public function generateTextureLoad( texture:Texture, textureProperty:String, uvIndexSnippet:String, depthSnippet:String, levelSnippet:String = "0u" ):String {
		if ( depthSnippet != null ) {
			return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${depthSnippet}, ${levelSnippet})';
		} else {
			return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${levelSnippet})';
		}
	}

	public function generateTextureStore( texture:Texture, textureProperty:String, uvIndexSnippet:String, valueSnippet:String ):String {
		return 'textureStore(${textureProperty}, ${uvIndexSnippet}, ${valueSnippet})';
	}

	public function isUnfilterable( texture:Texture ):Bool {
		return this.getComponentTypeFromTexture( texture ) != "float" || ( texture.isDataTexture && texture.type == FloatType );
	}

	override public function generateTexture( texture:Texture, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		var snippet:String;

		if ( texture.isVideoTexture ) {
			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );
		} else if ( this.isUnfilterable( texture ) ) {
			snippet = this.generateTextureLod( texture, textureProperty, uvSnippet, "0", depthSnippet, shaderStage );
		} else {
			snippet = this._generateTextureSample( texture, textureProperty, uvSnippet, depthSnippet, shaderStage );
		}

		return snippet;
	}

	override public function generateTextureGrad( texture:Texture, textureProperty:String, uvSnippet:String, gradSnippet:Array<String>, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			// TODO handle i32 or u32 --> uvSnippet, array_index: A, ddx, ddy
			return 'textureSampleGrad(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${gradSnippet[0]}, ${gradSnippet[1]})';
		} else {
			throw "WebGPURenderer: THREE.TextureNode.gradient() does not support ${shaderStage} shader.";
		}
	}

	override public function generateTextureCompare( texture:Texture, textureProperty:String, uvSnippet:String, compareSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			return 'textureSampleCompare(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${compareSnippet})';
		} else {
			throw "WebGPURenderer: THREE.DepthTexture.compareFunction() does not support ${shaderStage} shader.";
		}
	}

	override public function generateTextureLevel( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		var snippet:String;

		if ( texture.isVideoTexture ) {
			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );
		} else {
			snippet = this._generateTextureSampleLevel( texture, textureProperty, uvSnippet, levelSnippet, depthSnippet, shaderStage );
		}

		return snippet;
	}

	override public function getPropertyName( node:Node, shaderStage:String = this.shaderStage ):String {
		if ( node.isNodeVarying && node.needsInterpolation ) {
			if ( shaderStage == "vertex" ) {
				return 'varyings.${node.name}';
			}
		} else if ( node.isNodeUniform ) {
			var name = node.name;
			var type = node.type;

			if ( type == "texture" || type == "cubeTexture" || type == "storageTexture" ) {
				return name;
			} else if ( type == "buffer" || type == "storageBuffer" ) {
				return 'NodeBuffer_${node.id}.${name}';
			} else {
				return node.groupNode.name + '.' + name;
			}
		}

		return super.getPropertyName( node );
	}

	public function _getUniformGroupCount( shaderStage:String ):Int {
		return this.uniforms[shaderStage].keys().length;
	}

	override public function getFunctionOperator( op:String ):String {
		var fnOp = wgslFnOpLib[op];

		if ( fnOp != null ) {
			this._include( fnOp );
			return fnOp;
		}

		return null;
	}

	override public function getUniformFromNode( node:Node, type:String, shaderStage:String, name:String = null ):{ name:String, node:Node } {
		var uniformNode = super.getUniformFromNode( node, type, shaderStage, name );
		var nodeData = this.getDataFromNode( node, shaderStage, this.globalCache );

		if ( nodeData.uniformGPU == null ) {
			var uniformGPU:Dynamic;
			var bindings = this.bindings[shaderStage];

			if ( type == "texture" || type == "cubeTexture" || type == "storageTexture" ) {
				var texture:Dynamic;

				if ( type == "texture" || type == "storageTexture" ) {
					texture = new NodeSampledTexture( uniformNode.name, uniformNode.node );
				} else if ( type == "cubeTexture" ) {
					texture = new NodeSampledCubeTexture( uniformNode.name, uniformNode.node );
				}

				texture.store = node.isStoreTextureNode;
				texture.setVisibility( gpuShaderStageLib[shaderStage] );

				if ( shaderStage == "fragment" && this.isUnfilterable( node.value ) == false && texture.store == false ) {
					var sampler = new NodeSampler( '${uniformNode.name}_sampler', uniformNode.node );
					sampler.setVisibility( gpuShaderStageLib[shaderStage] );

					bindings.push( sampler, texture );

					uniformGPU = [sampler, texture];
				} else {
					bindings.push( texture );

					uniformGPU = [texture];
				}
			} else if ( type == "buffer" || type == "storageBuffer" ) {
				var bufferClass:Class<Dynamic> = type == "storageBuffer" ? NodeStorageBuffer : NodeUniformBuffer;
				var buffer = new bufferClass( node );
				buffer.setVisibility( gpuShaderStageLib[shaderStage] );

				bindings.push( buffer );

				uniformGPU = buffer;
			} else {
				var group = node.groupNode;
				var groupName = group.name;

				var uniformsStage = this.uniformGroups.get( shaderStage );
				if ( uniformsStage == null ) {
					uniformsStage = new Map();
					this.uniformGroups.set( shaderStage, uniformsStage );
				}

				var uniformsGroup = uniformsStage.get( groupName );

				if ( uniformsGroup == null ) {
					uniformsGroup = new NodeUniformsGroup( groupName, group );
					uniformsGroup.setVisibility( gpuShaderStageLib[shaderStage] );

					uniformsStage.set( groupName, uniformsGroup );

					bindings.push( uniformsGroup );
				}

				uniformGPU = this.getNodeUniform( uniformNode, type );

				uniformsGroup.addUniform( uniformGPU );
			}

			nodeData.uniformGPU = uniformGPU;

			if ( shaderStage == "vertex" ) {
				this.bindingsOffset["fragment"] = bindings.length;
			}
		}

		return uniformNode;
	}

	override public function isReference( type:String ):Bool {
		return super.isReference( type ) || type == "texture_2d" || type == "texture_cube" || type == "texture_depth_2d" || type == "texture_storage_2d";
	}

	public function getBuiltin( name:String, property:String, type:String, shaderStage:String = this.shaderStage ):String {
		var map = this.builtins.get( shaderStage );
		if ( map == null ) {
			map = new Map();
			this.builtins.set( shaderStage, map );
		}

		if ( !map.exists( name ) ) {
			map.set( name, { name:name, property:property, type:type } );
		}

		return property;
	}

	override public function getVertexIndex():String {
		if ( this.shaderStage == "vertex" ) {
			return this.getBuiltin( "vertex_index", "vertexIndex", "u32", "attribute" );
		}

		return "vertexIndex";
	}

	override public function buildFunctionCode( shaderNode:NodeFunction ):String {
		var layout = shaderNode.layout;
		var flowData = this.flowShaderNode( shaderNode );

		var parameters:Array<String> = [];

		for ( input in layout.inputs ) {
			parameters.push( input.name + ' : ' + this.getType( input.type ) );
		}

		//

		var code = 'fn ${layout.name}(${parameters.join(", ")}) -> ${this.getType( layout.type )} {\n${flowData.vars}\n${flowData.code}\n\treturn ${flowData.result};\n\n}';

		//

		return code;
	}

	override public function getInstanceIndex():String {
		if ( this.shaderStage == "vertex" ) {
			return this.getBuiltin( "instance_index", "instanceIndex", "u32", "attribute" );
		}

		return "instanceIndex";
	}

	override public function getFrontFacing():String {
		return this.getBuiltin( "front_facing", "isFront", "bool" );
	}

	override public function getFragCoord():String {
		return '${this.getBuiltin( "position", "fragCoord", "vec4<f32>" )}.xyz';
	}

	override public function getFragDepth():String {
		return 'output.${this.getBuiltin( "frag_depth", "depth", "f32", "output" )}';
	}

	override public function isFlipY():Bool {
		return false;
	}

	public function getBuiltins( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var builtins = this.builtins.get( shaderStage );

		if ( builtins != null ) {
			for ( builtin in builtins.values() ) {
				snippets.push( `@builtin(${builtin.name}) ${builtin.property} : ${builtin.type}` );
			}
		}

		return snippets.join( ',\n\t' );
	}

	public function getAttributes( shaderStage:String ):String {
		var snippets:Array<String> = [];

		if ( shaderStage == "compute" ) {
			this.getBuiltin( "global_invocation_id", "id", "vec3<u32>", "attribute" );
		}

		if ( shaderStage == "vertex" || shaderStage == "compute" ) {
			var builtins = this.getBuiltins( "attribute" );

			if ( builtins != null ) snippets.push( builtins );

			var attributes = this.getAttributesArray();

			for ( i in 0...attributes.length ) {
				var attribute = attributes[i];
				var name = attribute.name;
				var type = this.getType( attribute.type );

				snippets.push( `@location(${i}) ${name} : ${type}` );
			}
		}

		return snippets.join( ',\n\t' );
	}

	public function getStructMembers( struct:NodeStruct ):String {
		var snippets:Array<String> = [];
		var members = struct.getMemberTypes();

		for ( i in 0...members.length ) {
			var member = members[i];
			snippets.push( `\t@location(${i}) m${i} : ${member}<f32>` );
		}

		return snippets.join( ',\n' );
	}

	public function getStructs( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var structs = this.structs[shaderStage];

		for ( i in 0...structs.length ) {
			var struct = structs[i];
			var name = struct.name;

			var snippet = `\struct ${name} {\n`;
			snippet += this.getStructMembers( struct );
			snippet += '\n}';

			snippets.push( snippet );
		}

		return snippets.join( '\n\n' );
	}

	public function getVar( type:String, name:String ):String {
		return 'var ${name} : ${this.getType( type )}';
	}

	public function getVars( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var vars = this.vars[shaderStage];

		if ( vars != null ) {
			for ( variable in vars ) {
				snippets.push( `\t${this.getVar( variable.type, variable.name )};` );
			}
		}

		return `\n${snippets.join( '\n' )}\n`;
	}

	public function getVaryings( shaderStage:String ):String {
		var snippets:Array<String> = [];

		if ( shaderStage == "vertex" ) {
			this.getBuiltin( "position", "Vertex", "vec4<f32>", "vertex" );
		}

		if ( shaderStage == "vertex" || shaderStage == "fragment" ) {
			var varyings = this.varyings;
			var vars = this.vars[shaderStage];

			for ( i in 0...varyings.length ) {
				var varying = varyings[i];

				if ( varying.needsInterpolation ) {
					var attributesSnippet = `@location(${i})`;

					if ( Type.regex( varying.type, "^(int|uint|ivec|uvec)" ) ) {
						attributesSnippet += ' @interpolate( flat )';
					}

					snippets.push( `${attributesSnippet} ${varying.name} : ${this.getType( varying.type )}` );
				} else if ( shaderStage == "vertex" && !vars.contains( varying ) ) {
					vars.push( varying );
				}
			}
		}

		var builtins = this.getBuiltins( shaderStage );

		if ( builtins != null ) snippets.push( builtins );

		var code = snippets.join( ',\n\t' );

		return shaderStage == "vertex" ? this._getWGSLStruct( "VaryingsStruct", '\t' + code ) : code;
	}

	public function getUniforms( shaderStage:String ):String {
		var uniforms = this.uniforms[shaderStage];

		var bindingSnippets:Array<String> = [];
		var bufferSnippets:Array<String> = [];
		var structSnippets:Array<String> = [];
		var uniformGroups:Map<String, { index:Int, snippets:Array<String> }> = new Map();

		var index = this.bindingsOffset[shaderStage];

		for ( uniform in uniforms ) {
			if ( uniform.type == "texture" || uniform.type == "cubeTexture" || uniform.type == "storageTexture" ) {
				var texture = uniform.node.value;

				if ( shaderStage == "fragment" && this.isUnfilterable( texture ) == false && uniform.node.isStoreTextureNode == false ) {
					if ( texture.isDepthTexture && texture.compareFunction != null ) {
						bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name}_sampler : sampler_comparison;` );
					} else {
						bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name}_sampler : sampler;` );
					}
				}

				var textureType:String;

				if ( texture.isCubeTexture ) {
					textureType = "texture_cube<f32>";
				} else if ( texture.isDataArrayTexture ) {
					textureType = "texture_2d_array<f32>";
				} else if ( texture.isDepthTexture ) {
					textureType = "texture_depth_2d";
				} else if ( texture.isVideoTexture ) {
					textureType = "texture_external";
				} else if ( uniform.node.isStoreTextureNode ) {
					var format = WebGPUTextureUtils.getFormat( texture );
					textureType = `texture_storage_2d<${format}, write>`;
				} else {
					var componentPrefix = this.getComponentTypeFromTexture( texture ).charAt( 0 );
					textureType = `texture_2d<${componentPrefix}32>`;
				}

				bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name} : ${textureType};` );
			} else if ( uniform.type == "buffer" || uniform.type == "storageBuffer" ) {
				var bufferNode = uniform.node;
				var bufferType = this.getType( bufferNode.bufferType );
				var bufferCount = bufferNode.bufferCount;

				var bufferCountSnippet = bufferCount > 0 ? ', ' + bufferCount : '';
				var bufferSnippet = `\t${uniform.name} : array< ${bufferType}${bufferCountSnippet} >\n`;
				var bufferAccessMode = bufferNode.isStorageBufferNode ? "storage,read_write" : "uniform";

				bufferSnippets.push( this._getWGSLStructBinding( "NodeBuffer_" + bufferNode.id, bufferSnippet, bufferAccessMode, index++ ) );
			} else {
				var vectorType = this.getType( this.getVectorType( uniform.type ) );
				var groupName = uniform.groupNode.name;

				var group = uniformGroups.get( groupName );
				if ( group == null ) {
					group = { index:index++, snippets:[] };
					uniformGroups.set( groupName, group );
				}

				group.snippets.push( `\t${uniform.name} : ${vectorType}` );
			}
		}

		for ( name in uniformGroups.keys() ) {
			var group = uniformGroups.get( name );

			structSnippets.push( this._getWGSLStructBinding( name, group.snippets.join( ',\n' ), "uniform", group.index ) );
		}

		var code = bindingSnippets.join( '\n' );
		code += bufferSnippets.join( '\n' );
		code += structSnippets.join( '\n' );

		return code;
	}

	override public function buildCode() {
		var shadersData = this.material != null ? { fragment: {}, vertex: {} } : { compute: {} };

		for ( shaderStage in shadersData.keys() ) {
			var stageData = shadersData[shaderStage];
			stageData.uniforms = this.getUniforms( shaderStage );
			stageData.attributes = this.getAttributes( shaderStage );
			stageData.varyings = this.getVaryings( shaderStage );
			stageData.structs = this.getStructs( shaderStage );
			stageData.vars = this.getVars( shaderStage );
			stageData.codes = this.getCodes( shaderStage );

			//

			var flow = '// code\n\n';
			flow += this.flowCode[shaderStage];

			var flowNodes = this.flowNodes[shaderStage];
			var mainNode = flowNodes[flowNodes.length - 1];

			var outputNode = mainNode.outputNode;
			var isOutputStruct = ( outputNode != null && outputNode.isOutputStructNode );

			for ( node in flowNodes ) {
				var flowSlotData = this.getFlowData( node );
				var slotName = node.name;

				if ( slotName != null ) {
					if ( flow.length > 0 ) flow += '\n';
					flow += `\t// flow -> ${slotName}\n\t`;
				}

				flow += `${flowSlotData.code}\n\t`;

				if ( node == mainNode && shaderStage != "compute" ) {
					flow += '// result\n\n\t';

					if ( shaderStage == "vertex" ) {
						flow += `varyings.Vertex = ${flowSlotData.result};`;
					} else if ( shaderStage == "fragment" ) {
						if ( isOutputStruct ) {
							stageData.returnType = outputNode.nodeType;
							flow += `return ${flowSlotData.result};`;
						} else {
							var structSnippet = '\t@location(0) color: vec4<f32>';

							var builtins = this.getBuiltins( "output" );

							if ( builtins != null ) structSnippet += ',\n\t' + builtins;

							stageData.returnType = "OutputStruct";
							stageData.structs += this._getWGSLStruct( "OutputStruct", structSnippet );
							stageData.structs += '\nvar<private> output : OutputStruct;\n\n';

							flow += `output.color = ${flowSlotData.result};\n\n\treturn output;`;
						}
					}
				}
			}

			stageData.flow = flow;
		}

		if ( this.material != null ) {
			this.vertexShader = this._getWGSLVertexCode( shadersData.vertex );
			this.fragmentShader = this._getWGSLFragmentCode( shadersData.fragment );
		} else {
			this.computeShader = this._getWGSLComputeCode( shadersData.compute, ( this.object.workgroupSize != null ? this.object.workgroupSize : [64] ).join( ", " ) );
		}
	}

	override public function getMethod( method:String, output:String = null ):String {
		var wgslMethod:String;

		if ( output != null ) {
			wgslMethod = this._getWGSLMethod( method + '_' + output );
		}

		if ( wgslMethod == null ) {
			wgslMethod = this._getWGSLMethod( method );
		}

		return wgslMethod != null ? wgslMethod : method;
	}

	override public function getType( type:String ):String {
		return wgslTypeLib[type] != null ? wgslTypeLib[type] : type;
	}

	override public function isAvailable( name:String ):Bool {
		return supports[name];
	}

	public function _getWGSLMethod( method:String ):String {
		if ( wgslPolyfill[method] != null ) {
			this._include( method );
		}

		return wgslMethods[method];
	}

	public function _include( name:String ):CodeNode {
		var codeNode = wgslPolyfill[name];
		codeNode.build( this );

		if ( this.currentFunctionNode != null ) {
			this.currentFunctionNode.includes.push( codeNode );
		}

		return codeNode;
	}

	public function _getWGSLVertexCode( shaderData:Dynamic ):String {
		return `${this.getSignature()}

// uniforms
${shaderData.uniforms}

// varyings
${shaderData.varyings}
var<private> varyings : VaryingsStruct;

// codes
${shaderData.codes}

@vertex
fn main(${shaderData.attributes}) -> VaryingsStruct {

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

	return varyings;

}
`;
	}

	public function _getWGSLFragmentCode( shaderData:Dynamic ):String {
		return `${this.getSignature()}

// uniforms
${shaderData.uniforms}

// structs
${shaderData.structs}

// codes
${shaderData.codes}

@fragment
fn main(${shaderData.varyings}) -> ${shaderData.returnType} {

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

}
`;
	}

	public function _getWGSLComputeCode( shaderData:Dynamic, workgroupSize:String ):String {
		return `${this.getSignature()}
// system
var<private> instanceIndex : u32;

// uniforms
${shaderData.uniforms}

// codes
${shaderData.codes}

@compute @workgroup_size(${workgroupSize})
fn main(${shaderData.attributes}) {

	// system
	instanceIndex = id.x;

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

}
`;
	}

	public function _getWGSLStruct( name:String, vars:String ):String {
		return `
struct ${name} {
${vars}
};`;
	}

	public function _getWGSLStructBinding( name:String, vars:String, access:String, binding:Int = 0, group:Int = 0 ):String {
		var structName = name + "Struct";
		var structSnippet = this._getWGSLStruct( structName, vars );

		return `${structSnippet}
@binding(${binding}) @group(${group})
var<${access}> ${name} : ${structName};`;
	}

}

// GPUShaderStage is not defined in browsers not supporting WebGPU
#if webgpu
var GPUShaderStage = WebGPUShaderStage;
#end

var gpuShaderStageLib:Map<String, Int> = {
	"vertex": GPUShaderStage != null ? GPUShaderStage.VERTEX : 1,
	"fragment": GPUShaderStage != null ? GPUShaderStage.FRAGMENT : 2,
	"compute": GPUShaderStage != null ? GPUShaderStage.COMPUTE : 4
};

var supports:Map<String, Bool> = {
	"instance": true,
	"storageBuffer": true
};

var wgslFnOpLib:Map<String, String> = {
	"^^": "threejs_xor"
};

var wgslTypeLib:Map<String, String> = {
	"float": "f32",
	"int": "i32",
	"uint": "u32",
	"bool": "bool",
	"color": "vec3<f32>",

	"vec2": "vec2<f32>",
	"ivec2": "vec2<i32>",
	"uvec2": "vec2<u32>",
	"bvec2": "vec2<bool>",

	"vec3": "vec3<f32>",
	"ivec3": "vec3<i32>",
	"uvec3": "vec3<u32>",
	"bvec3": "vec3<bool>",

	"vec4": "vec4<f32>",
	"ivec4": "vec4<i32>",
	"uvec4": "vec4<u32>",
	"bvec4": "vec4<bool>",

	"mat2": "mat2x2<f32>",
	"imat2": "mat2x2<i32>",
	"umat2": "mat2x2<u32>",
	"bmat2": "mat2x2<bool>",

	"mat3": "mat3x3<f32>",
	"imat3": "mat3x3<i32>",
	"umat3": "mat3x3<u32>",
	"bmat3": "mat3x3<bool>",

	"mat4": "mat4x4<f32>",
	"imat4": "mat4x4<i32>",
	"umat4": "mat4x4<u32>",
	"bmat4": "mat4x4<bool>"
};

var wgslMethods:Map<String, String> = {
	"dFdx": "dpdx",
	"dFdy": "- dpdy",
	"mod_float": "threejs_mod_float",
	"mod_vec2": "threejs_mod_vec2",
	"mod_vec3": "threejs_mod_vec3",
	"mod_vec4": "threejs_mod_vec4",
	"equals_bool": "threejs_equals_bool",
	"equals_bvec2": "threejs_equals_bvec2",
	"equals_bvec3": "threejs_equals_bvec3",
	"equals_bvec4": "threejs_equals_bvec4",
	"lessThanEqual": "threejs_lessThanEqual",
	"greaterThan": "threejs_greaterThan",
	"inversesqrt": "inverseSqrt",
	"bitcast": "bitcast<f32>"
};

var wgslPolyfill:Map
var wgslPolyfill:Map<String, CodeNode> = {
	"threejs_xor": new CodeNode( `
fn threejs_xor( a : bool, b : bool ) -> bool {

	return ( a || b ) && !( a && b );

}
` ),
	"lessThanEqual": new CodeNode( `
fn threejs_lessThanEqual( a : vec3<f32>, b : vec3<f32> ) -> vec3<bool> {

	return vec3<bool>( a.x <= b.x, a.y <= b.y, a.z <= b.z );

}
` ),
	"greaterThan": new CodeNode( `
fn threejs_greaterThan( a : vec3<f32>, b : vec3<f32> ) -> vec3<bool> {

	return vec3<bool>( a.x > b.x, a.y > b.y, a.z > b.z );

}
` ),
	"mod_float": new CodeNode( 'fn threejs_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }' ),
	"mod_vec2": new CodeNode( 'fn threejs_mod_vec2( x : vec2f, y : vec2f ) -> vec2f { return x - y * floor( x / y ); }' ),
	"mod_vec3": new CodeNode( 'fn threejs_mod_vec3( x : vec3f, y : vec3f ) -> vec3f { return x - y * floor( x / y ); }' ),
	"mod_vec4": new CodeNode( 'fn threejs_mod_vec4( x : vec4f, y : vec4f ) -> vec4f { return x - y * floor( x / y ); }' ),
	"equals_bool": new CodeNode( 'fn threejs_equals_bool( a : bool, b : bool ) -> bool { return a == b; }' ),
	"equals_bvec2": new CodeNode( 'fn threejs_equals_bvec2( a : vec2f, b : vec2f ) -> vec2<bool> { return vec2<bool>( a.x == b.x, a.y == b.y ); }' ),
	"equals_bvec3": new CodeNode( 'fn threejs_equals_bvec3( a : vec3f, b : vec3f ) -> vec3<bool> { return vec3<bool>( a.x == b.x, a.y == b.y, a.z == b.z ); }' ),
	"equals_bvec4": new CodeNode( 'fn threejs_equals_bvec4( a : vec4f, b : vec4f ) -> vec4<bool> { return vec4<bool>( a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w ); }' ),
	"repeatWrapping": new CodeNode( `
fn threejs_repeatWrapping( uv : vec2<f32>, dimension : vec2<u32> ) -> vec2<u32> {

	let uvScaled = vec2<u32>( uv * vec2<f32>( dimension ) );

	return ( ( uvScaled % dimension ) + dimension ) % dimension;

}
` )
};

class WGSLNodeBuilder extends NodeBuilder {

	public uniformGroups:Map<String, NodeUniformsGroup> = new Map();
	public builtins:Map<String, Map<String, { name:String, property:String, type:String }>> = new Map();

	public function new( object:Object3D, renderer:Dynamic, scene:Scene = null ) {
		super( object, renderer, new WGSLNodeParser(), scene );
	}

	override public function needsColorSpaceToLinear( texture:Texture ):Bool {
		return texture.isVideoTexture && texture.colorSpace != NoColorSpace;
	}

	override public function _generateTextureSample( texture:Texture, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			if ( depthSnippet != null ) {
				return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${depthSnippet})';
			} else {
				return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet})';
			}
		} else {
			return this.generateTextureLod( texture, textureProperty, uvSnippet );
		}
	}

	override public function _generateVideoSample( textureProperty:String, uvSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			return 'textureSampleBaseClampToEdge(${textureProperty}, ${textureProperty}_sampler, vec2<f32>(${uvSnippet}.x, 1.0 - ${uvSnippet}.y))';
		} else {
			throw "WebGPURenderer: THREE.VideoTexture does not support ${shaderStage} shader.";
		}
	}

	override public function _generateTextureSampleLevel( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" && this.isUnfilterable( texture ) == false ) {
			return 'textureSampleLevel(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${levelSnippet})';
		} else {
			return this.generateTextureLod( texture, textureProperty, uvSnippet, levelSnippet );
		}
	}

	public function generateTextureLod( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String = "0" ):String {
		this._include( "repeatWrapping" );
		var dimension = 'textureDimensions(${textureProperty}, 0)';
		return 'textureLoad(${textureProperty}, threejs_repeatWrapping(${uvSnippet}, ${dimension}), i32(${levelSnippet}))';
	}

	public function generateTextureLoad( texture:Texture, textureProperty:String, uvIndexSnippet:String, depthSnippet:String, levelSnippet:String = "0u" ):String {
		if ( depthSnippet != null ) {
			return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${depthSnippet}, ${levelSnippet})';
		} else {
			return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${levelSnippet})';
		}
	}

	public function generateTextureStore( texture:Texture, textureProperty:String, uvIndexSnippet:String, valueSnippet:String ):String {
		return 'textureStore(${textureProperty}, ${uvIndexSnippet}, ${valueSnippet})';
	}

	public function isUnfilterable( texture:Texture ):Bool {
		return this.getComponentTypeFromTexture( texture ) != "float" || ( texture.isDataTexture && texture.type == FloatType );
	}

	override public function generateTexture( texture:Texture, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		var snippet:String;

		if ( texture.isVideoTexture ) {
			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );
		} else if ( this.isUnfilterable( texture ) ) {
			snippet = this.generateTextureLod( texture, textureProperty, uvSnippet, "0", depthSnippet, shaderStage );
		} else {
			snippet = this._generateTextureSample( texture, textureProperty, uvSnippet, depthSnippet, shaderStage );
		}

		return snippet;
	}

	override public function generateTextureGrad( texture:Texture, textureProperty:String, uvSnippet:String, gradSnippet:Array<String>, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			// TODO handle i32 or u32 --> uvSnippet, array_index: A, ddx, ddy
			return 'textureSampleGrad(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${gradSnippet[0]}, ${gradSnippet[1]})';
		} else {
			throw "WebGPURenderer: THREE.TextureNode.gradient() does not support ${shaderStage} shader.";
		}
	}

	override public function generateTextureCompare( texture:Texture, textureProperty:String, uvSnippet:String, compareSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			return 'textureSampleCompare(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${compareSnippet})';
		} else {
			throw "WebGPURenderer: THREE.DepthTexture.compareFunction() does not support ${shaderStage} shader.";
		}
	}

	override public function generateTextureLevel( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		var snippet:String;

		if ( texture.isVideoTexture ) {
			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );
		} else {
			snippet = this._generateTextureSampleLevel( texture, textureProperty, uvSnippet, levelSnippet, depthSnippet, shaderStage );
		}

		return snippet;
	}

	override public function getPropertyName( node:Node, shaderStage:String = this.shaderStage ):String {
		if ( node.isNodeVarying && node.needsInterpolation ) {
			if ( shaderStage == "vertex" ) {
				return 'varyings.${node.name}';
			}
		} else if ( node.isNodeUniform ) {
			var name = node.name;
			var type = node.type;

			if ( type == "texture" || type == "cubeTexture" || type == "storageTexture" ) {
				return name;
			} else if ( type == "buffer" || type == "storageBuffer" ) {
				return 'NodeBuffer_${node.id}.${name}';
			} else {
				return node.groupNode.name + '.' + name;
			}
		}

		return super.getPropertyName( node );
	}

	public function _getUniformGroupCount( shaderStage:String ):Int {
		return this.uniforms[shaderStage].keys().length;
	}

	override public function getFunctionOperator( op:String ):String {
		var fnOp = wgslFnOpLib[op];

		if ( fnOp != null ) {
			this._include( fnOp );
			return fnOp;
		}

		return null;
	}

	override public function getUniformFromNode( node:Node, type:String, shaderStage:String, name:String = null ):{ name:String, node:Node } {
		var uniformNode = super.getUniformFromNode( node, type, shaderStage, name );
		var nodeData = this.getDataFromNode( node, shaderStage, this.globalCache );

		if ( nodeData.uniformGPU == null ) {
			var uniformGPU:Dynamic;
			var bindings = this.bindings[shaderStage];

			if ( type == "texture" || type == "cubeTexture" || type == "storageTexture" ) {
				var texture:Dynamic;

				if ( type == "texture" || type == "storageTexture" ) {
					texture = new NodeSampledTexture( uniformNode.name, uniformNode.node );
				} else if ( type == "cubeTexture" ) {
					texture = new NodeSampledCubeTexture( uniformNode.name, uniformNode.node );
				}

				texture.store = node.isStoreTextureNode;
				texture.setVisibility( gpuShaderStageLib[shaderStage] );

				if ( shaderStage == "fragment" && this.isUnfilterable( node.value ) == false && texture.store == false ) {
					var sampler = new NodeSampler( '${uniformNode.name}_sampler', uniformNode.node );
					sampler.setVisibility( gpuShaderStageLib[shaderStage] );

					bindings.push( sampler, texture );

					uniformGPU = [sampler, texture];
				} else {
					bindings.push( texture );

					uniformGPU = [texture];
				}
			} else if ( type == "buffer" || type == "storageBuffer" ) {
				var bufferClass:Class<Dynamic> = type == "storageBuffer" ? NodeStorageBuffer : NodeUniformBuffer;
				var buffer = new bufferClass( node );
				buffer.setVisibility( gpuShaderStageLib[shaderStage] );

				bindings.push( buffer );

				uniformGPU = buffer;
			} else {
				var group = node.groupNode;
				var groupName = group.name;

				var uniformsStage = this.uniformGroups.get( shaderStage );
				if ( uniformsStage == null ) {
					uniformsStage = new Map();
					this.uniformGroups.set( shaderStage, uniformsStage );
				}

				var uniformsGroup = uniformsStage.get( groupName );

				if ( uniformsGroup == null ) {
					uniformsGroup = new NodeUniformsGroup( groupName, group );
					uniformsGroup.setVisibility( gpuShaderStageLib[shaderStage] );

					uniformsStage.set( groupName, uniformsGroup );

					bindings.push( uniformsGroup );
				}

				uniformGPU = this.getNodeUniform( uniformNode, type );

				uniformsGroup.addUniform( uniformGPU );
			}

			nodeData.uniformGPU = uniformGPU;

			if ( shaderStage == "vertex" ) {
				this.bindingsOffset["fragment"] = bindings.length;
			}
		}

		return uniformNode;
	}

	override public function isReference( type:String ):Bool {
		return super.isReference( type ) || type == "texture_2d" || type == "texture_cube" || type == "texture_depth_2d" || type == "texture_storage_2d";
	}

	public function getBuiltin( name:String, property:String, type:String, shaderStage:String = this.shaderStage ):String {
		var map = this.builtins.get( shaderStage );
		if ( map == null ) {
			map = new Map();
			this.builtins.set( shaderStage, map );
		}

		if ( !map.exists( name ) ) {
			map.set( name, { name:name, property:property, type:type } );
		}

		return property;
	}

	override public function getVertexIndex():String {
		if ( this.shaderStage == "vertex" ) {
			return this.getBuiltin( "vertex_index", "vertexIndex", "u32", "attribute" );
		}

		return "vertexIndex";
	}

	override public function buildFunctionCode( shaderNode:NodeFunction ):String {
		var layout = shaderNode.layout;
		var flowData = this.flowShaderNode( shaderNode );

		var parameters:Array<String> = [];

		for ( input in layout.inputs ) {
			parameters.push( input.name + ' : ' + this.getType( input.type ) );
		}

		//

		var code = 'fn ${layout.name}(${parameters.join(", ")}) -> ${this.getType( layout.type )} {\n${flowData.vars}\n${flowData.code}\n\treturn ${flowData.result};\n\n}';

		//

		return code;
	}

	override public function getInstanceIndex():String {
		if ( this.shaderStage == "vertex" ) {
			return this.getBuiltin( "instance_index", "instanceIndex", "u32", "attribute" );
		}

		return "instanceIndex";
	}

	override public function getFrontFacing():String {
		return this.getBuiltin( "front_facing", "isFront", "bool" );
	}

	override public function getFragCoord():String {
		return '${this.getBuiltin( "position", "fragCoord", "vec4<f32>" )}.xyz';
	}

	override public function getFragDepth():String {
		return 'output.${this.getBuiltin( "frag_depth", "depth", "f32", "output" )}';
	}

	override public function isFlipY():Bool {
		return false;
	}

	public function getBuiltins( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var builtins = this.builtins.get( shaderStage );

		if ( builtins != null ) {
			for ( builtin in builtins.values() ) {
				snippets.push( `@builtin(${builtin.name}) ${builtin.property} : ${builtin.type}` );
			}
		}

		return snippets.join( ',\n\t' );
	}

	public function getAttributes( shaderStage:String ):String {
		var snippets:Array<String> = [];

		if ( shaderStage == "compute" ) {
			this.getBuiltin( "global_invocation_id", "id", "vec3<u32>", "attribute" );
		}

		if ( shaderStage == "vertex" || shaderStage == "compute" ) {
			var builtins = this.getBuiltins( "attribute" );

			if ( builtins != null ) snippets.push( builtins );

			var attributes = this.getAttributesArray();

			for ( i in 0...attributes.length ) {
				var attribute = attributes[i];
				var name = attribute.name;
				var type = this.getType( attribute.type );

				snippets.push( `@location(${i}) ${name} : ${type}` );
			}
		}

		return snippets.join( ',\n\t' );
	}

	public function getStructMembers( struct:NodeStruct ):String {
		var snippets:Array<String> = [];
		var members = struct.getMemberTypes();

		for ( i in 0...members.length ) {
			var member = members[i];
			snippets.push( `\t@location(${i}) m${i} : ${member}<f32>` );
		}

		return snippets.join( ',\n' );
	}

	public function getStructs( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var structs = this.structs[shaderStage];

		for ( i in 0...structs.length ) {
			var struct = structs[i];
			var name = struct.name;

			var snippet = `\struct ${name} {\n`;
			snippet += this.getStructMembers( struct );
			snippet += '\n}';

			snippets.push( snippet );
		}

		return snippets.join( '\n\n' );
	}

	public function getVar( type:String, name:String ):String {
		return 'var ${name} : ${this.getType( type )}';
	}

	public function getVars( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var vars = this.vars[shaderStage];

		if ( vars != null ) {
			for ( variable in vars ) {
				snippets.push( `\t${this.getVar( variable.type, variable.name )};` );
			}
		}

		return `\n${snippets.join( '\n' )}\n`;
	}

	public function getVaryings( shaderStage:String ):String {
		var snippets:Array<String> = [];

		if ( shaderStage == "vertex" ) {
			this.getBuiltin( "position", "Vertex", "vec4<f32>", "vertex" );
		}

		if ( shaderStage == "vertex" || shaderStage == "fragment" ) {
			var varyings = this.varyings;
			var vars = this.vars[shaderStage];

			for ( i in 0...varyings.length ) {
				var varying = varyings[i];

				if ( varying.needsInterpolation ) {
					var attributesSnippet = `@location(${i})`;

					if ( Type.regex( varying.type, "^(int|uint|ivec|uvec)" ) ) {
						attributesSnippet += ' @interpolate( flat )';
					}

					snippets.push( `${attributesSnippet} ${varying.name} : ${this.getType( varying.type )}` );
				} else if ( shaderStage == "vertex" && !vars.contains( varying ) ) {
					vars.push( varying );
				}
			}
		}

		var builtins = this.getBuiltins( shaderStage );

		if ( builtins != null ) snippets.push( builtins );

		var code = snippets.join( ',\n\t' );

		return shaderStage == "vertex" ? this._getWGSLStruct( "VaryingsStruct", '\t' + code ) : code;
	}

	public function getUniforms( shaderStage:String ):String {
		var uniforms = this.uniforms[shaderStage];

		var bindingSnippets:Array<String> = [];
		var bufferSnippets:Array<String> = [];
		var structSnippets:Array<String> = [];
		var uniformGroups:Map<String, { index:Int, snippets:Array<String> }> = new Map();

		var index = this.bindingsOffset[shaderStage];

		for ( uniform in uniforms ) {
			if ( uniform.type == "texture" || uniform.type == "cubeTexture" || uniform.type == "storageTexture" ) {
				var texture = uniform.node.value;

				if ( shaderStage == "fragment" && this.isUnfilterable( texture ) == false && uniform.node.isStoreTextureNode == false ) {
					if ( texture.isDepthTexture && texture.compareFunction != null ) {
						bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name}_sampler : sampler_comparison;` );
					} else {
						bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name}_sampler : sampler;` );
					}
				}

				var textureType:String;

				if ( texture.isCubeTexture ) {
					textureType = "texture_cube<f32>";
				} else if ( texture.isDataArrayTexture ) {
					textureType = "texture_2d_array<f32>";
				} else if ( texture.isDepthTexture ) {
					textureType = "texture_depth_2d";
				} else if ( texture.isVideoTexture ) {
					textureType = "texture_external";
				} else if ( uniform.node.isStoreTextureNode ) {
					var format = WebGPUTextureUtils.getFormat( texture );
					textureType = `texture_storage_2d<${format}, write>`;
				} else {
					var componentPrefix = this.getComponentTypeFromTexture( texture ).charAt( 0 );
					textureType = `texture_2d<${componentPrefix}32>`;
				}

				bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name} : ${textureType};` );
			} else if ( uniform.type == "buffer" || uniform.type == "storageBuffer" ) {
				var bufferNode = uniform.node;
				var bufferType = this.getType( bufferNode.bufferType );
				var bufferCount = bufferNode.bufferCount;

				var bufferCountSnippet = bufferCount > 0 ? ', ' + bufferCount : '';
				var bufferSnippet = `\t${uniform.name} : array< ${bufferType}${bufferCountSnippet} >\n`;
				var bufferAccessMode = bufferNode.isStorageBufferNode ? "storage,read_write" : "uniform";

				bufferSnippets.push( this._getWGSLStructBinding( "NodeBuffer_" + bufferNode.id, bufferSnippet, bufferAccessMode, index++ ) );
			} else {
				var vectorType = this.getType( this.getVectorType( uniform.type ) );
				var groupName = uniform.groupNode.name;

				var group = uniformGroups.get( groupName );
				if ( group == null ) {
					group = { index:index++, snippets:[] };
					uniformGroups.set( groupName, group );
				}

				group.snippets.push( `\t${uniform.name} : ${vectorType}` );
			}
		}

		for ( name in uniformGroups.keys() ) {
			var group = uniformGroups.get( name );

			structSnippets.push( this._getWGSLStructBinding( name, group.snippets.join( ',\n' ), "uniform", group.index ) );
		}

		var code = bindingSnippets.join( '\n' );
		code += bufferSnippets.join( '\n' );
		code += structSnippets.join( '\n' );

		return code;
	}

	override public function buildCode() {
		var shadersData = this.material != null ? { fragment: {}, vertex: {} } : { compute: {} };

		for ( shaderStage in shadersData.keys() ) {
			var stageData = shadersData[shaderStage];
			stageData.uniforms = this.getUniforms( shaderStage );
			stageData.attributes = this.getAttributes( shaderStage );
			stageData.varyings = this.getVaryings( shaderStage );
			stageData.structs = this.getStructs( shaderStage );
			stageData.vars = this.getVars( shaderStage );
			stageData.codes = this.getCodes( shaderStage );

			//

			var flow = '// code\n\n';
			flow += this.flowCode[shaderStage];

			var flowNodes = this.flowNodes[shaderStage];
			var mainNode = flowNodes[flowNodes.length - 1];

			var outputNode = mainNode.outputNode;
			var isOutputStruct = ( outputNode != null && outputNode.isOutputStructNode );

			for ( node in flowNodes ) {
				var flowSlotData = this.getFlowData( node );
				var slotName = node.name;

				if ( slotName != null ) {
					if ( flow.length > 0 ) flow += '\n';
					flow += `\t// flow -> ${slotName}\n\t`;
				}

				flow += `${flowSlotData.code}\n\t`;

				if ( node == mainNode && shaderStage != "compute" ) {
					flow += '// result\n\n\t';

					if ( shaderStage == "vertex" ) {
						flow += `varyings.Vertex = ${flowSlotData.result};`;
					} else if ( shaderStage == "fragment" ) {
						if ( isOutputStruct ) {
							stageData.returnType = outputNode.nodeType;
							flow += `return ${flowSlotData.result};`;
						} else {
							var structSnippet = '\t@location(0) color: vec4<f32>';

							var builtins = this.getBuiltins( "output" );

							if ( builtins != null ) structSnippet += ',\n\t' + builtins;

							stageData.returnType = "OutputStruct";
							stageData.structs += this._getWGSLStruct( "OutputStruct", structSnippet );
							stageData.structs += '\nvar<private> output : OutputStruct;\n\n';

							flow += `output.color = ${flowSlotData.result};\n\n\treturn output;`;
						}
					}
				}
			}

			stageData.flow = flow;
		}

		if ( this.material != null ) {
			this.vertexShader = this._getWGSLVertexCode( shadersData.vertex );
			this.fragmentShader = this._getWGSLFragmentCode( shadersData.fragment );
		} else {
			this.computeShader = this._getWGSLComputeCode( shadersData.compute, ( this.object.workgroupSize != null ? this.object.workgroupSize : [64] ).join( ", " ) );
		}
	}

	override public function getMethod( method:String, output:String = null ):String {
		var wgslMethod:String;

		if ( output != null ) {
			wgslMethod = this._getWGSLMethod( method + '_' + output );
		}

		if ( wgslMethod == null ) {
			wgslMethod = this._getWGSLMethod( method );
		}

		return wgslMethod != null ? wgslMethod : method;
	}

	override public function getType( type:String ):String {
		return wgslTypeLib[type] != null ? wgslTypeLib[type] : type;
	}

	override public function isAvailable( name:String ):Bool {
		return supports[name];
	}

	public function _getWGSLMethod( method:String ):String {
		if ( wgslPolyfill[method] != null ) {
			this._include( method );
		}

		return wgslMethods[method];
	}

	public function _include( name:String ):CodeNode {
		var codeNode = wgslPolyfill[name];
		codeNode.build( this );

		if ( this.currentFunctionNode != null ) {
			this.currentFunctionNode.includes.push( codeNode );
		}

		return codeNode;
	}

	public function _getWGSLVertexCode( shaderData:Dynamic ):String {
		return `${this.getSignature()}

// uniforms
${shaderData.uniforms}

// varyings
${shaderData.varyings}
var<private> varyings : VaryingsStruct;

// codes
${shaderData.codes}

@vertex
fn main(${shaderData.attributes}) -> VaryingsStruct {

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

	return varyings;

}
`;
	}

	public function _getWGSLFragmentCode( shaderData:Dynamic ):String {
		return `${this.getSignature()}

// uniforms
${shaderData.uniforms}

// structs
${shaderData.structs}

// codes
${shaderData.codes}

@fragment
fn main(${shaderData.varyings}) -> ${shaderData.returnType} {

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

}
`;
	}

	public function _getWGSLComputeCode( shaderData:Dynamic, workgroupSize:String ):String {
		return `${this.getSignature()}
// system
var<private> instanceIndex : u32;

// uniforms
${shaderData.uniforms}

// codes
${shaderData.codes}

@compute @workgroup_size(${workgroupSize})
fn main(${shaderData.attributes}) {

	// system
	instanceIndex = id.x;

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

}
`;
	}

	public function _getWGSLStruct( name:String, vars:String ):String {
		return `
struct ${name} {
${vars}
};`;
	}

	public function _getWGSLStructBinding( name:String, vars:String, access:String, binding:Int = 0, group:Int = 0 ):String {
		var structName = name + "Struct";
		var structSnippet = this._getWGSLStruct( structName, vars );

		return `${structSnippet}
@binding(${binding}) @group(${group})
var<${access}> ${name} : ${structName};`;
	}

}

// GPUShaderStage is not defined in browsers not supporting WebGPU
#if webgpu
var GPUShaderStage = WebGPUShaderStage;
#end

var gpuShaderStageLib:Map<String, Int> = {
	"vertex": GPUShaderStage != null ? GPUShaderStage.VERTEX : 1,
	"fragment": GPUShaderStage != null ? GPUShaderStage.FRAGMENT : 2,
	"compute": GPUShaderStage != null ? GPUShaderStage.COMPUTE : 4
};

var supports:Map<String, Bool> = {
	"instance": true,
	"storageBuffer": true
};

var wgslFnOpLib:Map<String, String> = {
	"^^": "threejs_xor"
};

var wgslTypeLib:Map<String, String> = {
	"float": "f32",
	"int": "i32",
	"uint": "u32",
	"bool": "bool",
	"color": "vec3<f32>",

	"vec2": "vec2<f32>",
	"ivec2": "vec2<i32>",
	"uvec2": "vec2<u32>",
	"bvec2": "vec2<bool>",

	"vec3": "vec3<f32>",
	"ivec3": "vec3<i32>",
	"uvec3": "vec3<u32>",
	"bvec3": "vec3<bool>",

	"vec4": "vec4<f32>",
	"ivec4": "vec4<i32>",
	"uvec4": "vec4<u32>",
	"bvec4": "vec4<bool>",

	"mat2": "mat2x2<f32>",
	"imat2": "mat2x2<i32>",
	"umat2": "mat2x2<u32>",
	"bmat2": "mat2x2<bool>",

	"mat3": "mat3x3<f32>",
	"imat3": "mat3x3<i32>",
	"umat3": "mat3x3<u32>",
	"bmat3": "mat3x3<bool>",

	"mat4": "mat4x4<f32>",
	"imat4": "mat4x4<i32>",
	"umat4": "mat4x4<u32>",
	"bmat4": "mat4x4<bool>"
};

var wgslMethods:Map<String, String> = {
	"dFdx": "dpdx",
	"dFdy": "- dpdy",
	"mod_float": "threejs_mod_float",
	"mod_vec2": "threejs_mod_vec2",
	"mod_vec3": "threejs_mod_vec3",
	"mod_vec4": "threejs_mod_vec4",
	"equals_bool": "threejs_equals_bool",
	"equals_bvec2": "threejs_equals_bvec2",
	"equals_bvec3": "threejs_equals_bvec3",
	"equals_bvec4": "threejs_equals_bvec4",
	"lessThanEqual": "threejs_lessThanEqual",
	"greaterThan": "threejs_greaterThan",
	"inversesqrt": "inverseSqrt",
	"bitcast": "bitcast<f32>"
};

var wgslPolyfill:Map
var wgslPolyfill:Map<String, CodeNode> = {
	"threejs_xor": new CodeNode( `
fn threejs_xor( a : bool, b : bool ) -> bool {

	return ( a || b ) && !( a && b );

}
` ),
	"lessThanEqual": new CodeNode( `
fn threejs_lessThanEqual( a : vec3<f32>, b : vec3<f32> ) -> vec3<bool> {

	return vec3<bool>( a.x <= b.x, a.y <= b.y, a.z <= b.z );

}
` ),
	"greaterThan": new CodeNode( `
fn threejs_greaterThan( a : vec3<f32>, b : vec3<f32> ) -> vec3<bool> {

	return vec3<bool>( a.x > b.x, a.y > b.y, a.z > b.z );

}
` ),
	"mod_float": new CodeNode( 'fn threejs_mod_float( x : f32, y : f32 ) -> f32 { return x - y * floor( x / y ); }' ),
	"mod_vec2": new CodeNode( 'fn threejs_mod_vec2( x : vec2f, y : vec2f ) -> vec2f { return x - y * floor( x / y ); }' ),
	"mod_vec3": new CodeNode( 'fn threejs_mod_vec3( x : vec3f, y : vec3f ) -> vec3f { return x - y * floor( x / y ); }' ),
	"mod_vec4": new CodeNode( 'fn threejs_mod_vec4( x : vec4f, y : vec4f ) -> vec4f { return x - y * floor( x / y ); }' ),
	"equals_bool": new CodeNode( 'fn threejs_equals_bool( a : bool, b : bool ) -> bool { return a == b; }' ),
	"equals_bvec2": new CodeNode( 'fn threejs_equals_bvec2( a : vec2f, b : vec2f ) -> vec2<bool> { return vec2<bool>( a.x == b.x, a.y == b.y ); }' ),
	"equals_bvec3": new CodeNode( 'fn threejs_equals_bvec3( a : vec3f, b : vec3f ) -> vec3<bool> { return vec3<bool>( a.x == b.x, a.y == b.y, a.z == b.z ); }' ),
	"equals_bvec4": new CodeNode( 'fn threejs_equals_bvec4( a : vec4f, b : vec4f ) -> vec4<bool> { return vec4<bool>( a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w ); }' ),
	"repeatWrapping": new CodeNode( `
fn threejs_repeatWrapping( uv : vec2<f32>, dimension : vec2<u32> ) -> vec2<u32> {

	let uvScaled = vec2<u32>( uv * vec2<f32>( dimension ) );

	return ( ( uvScaled % dimension ) + dimension ) % dimension;

}
` )
};

class WGSLNodeBuilder extends NodeBuilder {

	public uniformGroups:Map<String, NodeUniformsGroup> = new Map();
	public builtins:Map<String, Map<String, { name:String, property:String, type:String }>> = new Map();

	public function new( object:Object3D, renderer:Dynamic, scene:Scene = null ) {
		super( object, renderer, new WGSLNodeParser(), scene );
	}

	override public function needsColorSpaceToLinear( texture:Texture ):Bool {
		return texture.isVideoTexture && texture.colorSpace != NoColorSpace;
	}

	override public function _generateTextureSample( texture:Texture, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			if ( depthSnippet != null ) {
				return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${depthSnippet})';
			} else {
				return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet})';
			}
		} else {
			return this.generateTextureLod( texture, textureProperty, uvSnippet );
		}
	}

	override public function _generateVideoSample( textureProperty:String, uvSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			return 'textureSampleBaseClampToEdge(${textureProperty}, ${textureProperty}_sampler, vec2<f32>(${uvSnippet}.x, 1.0 - ${uvSnippet}.y))';
		} else {
			throw "WebGPURenderer: THREE.VideoTexture does not support ${shaderStage} shader.";
		}
	}

	override public function _generateTextureSampleLevel( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" && this.isUnfilterable( texture ) == false ) {
			return 'textureSampleLevel(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${levelSnippet})';
		} else {
			return this.generateTextureLod( texture, textureProperty, uvSnippet, levelSnippet );
		}
	}

	public function generateTextureLod( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String = "0" ):String {
		this._include( "repeatWrapping" );
		var dimension = 'textureDimensions(${textureProperty}, 0)';
		return 'textureLoad(${textureProperty}, threejs_repeatWrapping(${uvSnippet}, ${dimension}), i32(${levelSnippet}))';
	}

	public function generateTextureLoad( texture:Texture, textureProperty:String, uvIndexSnippet:String, depthSnippet:String, levelSnippet:String = "0u" ):String {
		if ( depthSnippet != null ) {
			return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${depthSnippet}, ${levelSnippet})';
		} else {
			return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${levelSnippet})';
		}
	}

	public function generateTextureStore( texture:Texture, textureProperty:String, uvIndexSnippet:String, valueSnippet:String ):String {
		return 'textureStore(${textureProperty}, ${uvIndexSnippet}, ${valueSnippet})';
	}

	public function isUnfilterable( texture:Texture ):Bool {
		return this.getComponentTypeFromTexture( texture ) != "float" || ( texture.isDataTexture && texture.type == FloatType );
	}

	override public function generateTexture( texture:Texture, textureProperty:String, uvSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		var snippet:String;

		if ( texture.isVideoTexture ) {
			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );
		} else if ( this.isUnfilterable( texture ) ) {
			snippet = this.generateTextureLod( texture, textureProperty, uvSnippet, "0", depthSnippet, shaderStage );
		} else {
			snippet = this._generateTextureSample( texture, textureProperty, uvSnippet, depthSnippet, shaderStage );
		}

		return snippet;
	}

	override public function generateTextureGrad( texture:Texture, textureProperty:String, uvSnippet:String, gradSnippet:Array<String>, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			// TODO handle i32 or u32 --> uvSnippet, array_index: A, ddx, ddy
			return 'textureSampleGrad(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${gradSnippet[0]}, ${gradSnippet[1]})';
		} else {
			throw "WebGPURenderer: THREE.TextureNode.gradient() does not support ${shaderStage} shader.";
		}
	}

	override public function generateTextureCompare( texture:Texture, textureProperty:String, uvSnippet:String, compareSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		if ( shaderStage == "fragment" ) {
			return 'textureSampleCompare(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${compareSnippet})';
		} else {
			throw "WebGPURenderer: THREE.DepthTexture.compareFunction() does not support ${shaderStage} shader.";
		}
	}

	override public function generateTextureLevel( texture:Texture, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:String, shaderStage:String = this.shaderStage ):String {
		var snippet:String;

		if ( texture.isVideoTexture ) {
			snippet = this._generateVideoSample( textureProperty, uvSnippet, shaderStage );
		} else {
			snippet = this._generateTextureSampleLevel( texture, textureProperty, uvSnippet, levelSnippet, depthSnippet, shaderStage );
		}

		return snippet;
	}

	override public function getPropertyName( node:Node, shaderStage:String = this.shaderStage ):String {
		if ( node.isNodeVarying && node.needsInterpolation ) {
			if ( shaderStage == "vertex" ) {
				return 'varyings.${node.name}';
			}
		} else if ( node.isNodeUniform ) {
			var name = node.name;
			var type = node.type;

			if ( type == "texture" || type == "cubeTexture" || type == "storageTexture" ) {
				return name;
			} else if ( type == "buffer" || type == "storageBuffer" ) {
				return 'NodeBuffer_${node.id}.${name}';
			} else {
				return node.groupNode.name + '.' + name;
			}
		}

		return super.getPropertyName( node );
	}

	public function _getUniformGroupCount( shaderStage:String ):Int {
		return this.uniforms[shaderStage].keys().length;
	}

	override public function getFunctionOperator( op:String ):String {
		var fnOp = wgslFnOpLib[op];

		if ( fnOp != null ) {
			this._include( fnOp );
			return fnOp;
		}

		return null;
	}

	override public function getUniformFromNode( node:Node, type:String, shaderStage:String, name:String = null ):{ name:String, node:Node } {
		var uniformNode = super.getUniformFromNode( node, type, shaderStage, name );
		var nodeData = this.getDataFromNode( node, shaderStage, this.globalCache );

		if ( nodeData.uniformGPU == null ) {
			var uniformGPU:Dynamic;
			var bindings = this.bindings[shaderStage];

			if ( type == "texture" || type == "cubeTexture" || type == "storageTexture" ) {
				var texture:Dynamic;

				if ( type == "texture" || type == "storageTexture" ) {
					texture = new NodeSampledTexture( uniformNode.name, uniformNode.node );
				} else if ( type == "cubeTexture" ) {
					texture = new NodeSampledCubeTexture( uniformNode.name, uniformNode.node );
				}

				texture.store = node.isStoreTextureNode;
				texture.setVisibility( gpuShaderStageLib[shaderStage] );

				if ( shaderStage == "fragment" && this.isUnfilterable( node.value ) == false && texture.store == false ) {
					var sampler = new NodeSampler( '${uniformNode.name}_sampler', uniformNode.node );
					sampler.setVisibility( gpuShaderStageLib[shaderStage] );

					bindings.push( sampler, texture );

					uniformGPU = [sampler, texture];
				} else {
					bindings.push( texture );

					uniformGPU = [texture];
				}
			} else if ( type == "buffer" || type == "storageBuffer" ) {
				var bufferClass:Class<Dynamic> = type == "storageBuffer" ? NodeStorageBuffer : NodeUniformBuffer;
				var buffer = new bufferClass( node );
				buffer.setVisibility( gpuShaderStageLib[shaderStage] );

				bindings.push( buffer );

				uniformGPU = buffer;
			} else {
				var group = node.groupNode;
				var groupName = group.name;

				var uniformsStage = this.uniformGroups.get( shaderStage );
				if ( uniformsStage == null ) {
					uniformsStage = new Map();
					this.uniformGroups.set( shaderStage, uniformsStage );
				}

				var uniformsGroup = uniformsStage.get( groupName );

				if ( uniformsGroup == null ) {
					uniformsGroup = new NodeUniformsGroup( groupName, group );
					uniformsGroup.setVisibility( gpuShaderStageLib[shaderStage] );

					uniformsStage.set( groupName, uniformsGroup );

					bindings.push( uniformsGroup );
				}

				uniformGPU = this.getNodeUniform( uniformNode, type );

				uniformsGroup.addUniform( uniformGPU );
			}

			nodeData.uniformGPU = uniformGPU;

			if ( shaderStage == "vertex" ) {
				this.bindingsOffset["fragment"] = bindings.length;
			}
		}

		return uniformNode;
	}

	override public function isReference( type:String ):Bool {
		return super.isReference( type ) || type == "texture_2d" || type == "texture_cube" || type == "texture_depth_2d" || type == "texture_storage_2d";
	}

	public function getBuiltin( name:String, property:String, type:String, shaderStage:String = this.shaderStage ):String {
		var map = this.builtins.get( shaderStage );
		if ( map == null ) {
			map = new Map();
			this.builtins.set( shaderStage, map );
		}

		if ( !map.exists( name ) ) {
			map.set( name, { name:name, property:property, type:type } );
		}

		return property;
	}

	override public function getVertexIndex():String {
		if ( this.shaderStage == "vertex" ) {
			return this.getBuiltin( "vertex_index", "vertexIndex", "u32", "attribute" );
		}

		return "vertexIndex";
	}

	override public function buildFunctionCode( shaderNode:NodeFunction ):String {
		var layout = shaderNode.layout;
		var flowData = this.flowShaderNode( shaderNode );

		var parameters:Array<String> = [];

		for ( input in layout.inputs ) {
			parameters.push( input.name + ' : ' + this.getType( input.type ) );
		}

		//

		var code = 'fn ${layout.name}(${parameters.join(", ")}) -> ${this.getType( layout.type )} {\n${flowData.vars}\n${flowData.code}\n\treturn ${flowData.result};\n\n}';

		//

		return code;
	}

	override public function getInstanceIndex():String {
		if ( this.shaderStage == "vertex" ) {
			return this.getBuiltin( "instance_index", "instanceIndex", "u32", "attribute" );
		}

		return "instanceIndex";
	}

	override public function getFrontFacing():String {
		return this.getBuiltin( "front_facing", "isFront", "bool" );
	}

	override public function getFragCoord():String {
		return '${this.getBuiltin( "position", "fragCoord", "vec4<f32>" )}.xyz';
	}

	override public function getFragDepth():String {
		return 'output.${this.getBuiltin( "frag_depth", "depth", "f32", "output" )}';
	}

	override public function isFlipY():Bool {
		return false;
	}

	public function getBuiltins( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var builtins = this.builtins.get( shaderStage );

		if ( builtins != null ) {
			for ( builtin in builtins.values() ) {
				snippets.push( `@builtin(${builtin.name}) ${builtin.property} : ${builtin.type}` );
			}
		}

		return snippets.join( ',\n\t' );
	}

	public function getAttributes( shaderStage:String ):String {
		var snippets:Array<String> = [];

		if ( shaderStage == "compute" ) {
			this.getBuiltin( "global_invocation_id", "id", "vec3<u32>", "attribute" );
		}

		if ( shaderStage == "vertex" || shaderStage == "compute" ) {
			var builtins = this.getBuiltins( "attribute" );

			if ( builtins != null ) snippets.push( builtins );

			var attributes = this.getAttributesArray();

			for ( i in 0...attributes.length ) {
				var attribute = attributes[i];
				var name = attribute.name;
				var type = this.getType( attribute.type );

				snippets.push( `@location(${i}) ${name} : ${type}` );
			}
		}

		return snippets.join( ',\n\t' );
	}

	public function getStructMembers( struct:NodeStruct ):String {
		var snippets:Array<String> = [];
		var members = struct.getMemberTypes();

		for ( i in 0...members.length ) {
			var member = members[i];
			snippets.push( `\t@location(${i}) m${i} : ${member}<f32>` );
		}

		return snippets.join( ',\n' );
	}

	public function getStructs( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var structs = this.structs[shaderStage];

		for ( i in 0...structs.length ) {
			var struct = structs[i];
			var name = struct.name;

			var snippet = `\struct ${name} {\n`;
			snippet += this.getStructMembers( struct );
			snippet += '\n}';

			snippets.push( snippet );
		}

		return snippets.join( '\n\n' );
	}

	public function getVar( type:String, name:String ):String {
		return 'var ${name} : ${this.getType( type )}';
	}

	public function getVars( shaderStage:String ):String {
		var snippets:Array<String> = [];
		var vars = this.vars[shaderStage];

		if ( vars != null ) {
			for ( variable in vars ) {
				snippets.push( `\t${this.getVar( variable.type, variable.name )};` );
			}
		}

		return `\n${snippets.join( '\n' )}\n`;
	}

	public function getVaryings( shaderStage:String ):String {
		var snippets:Array<String> = [];

		if ( shaderStage == "vertex" ) {
			this.getBuiltin( "position", "Vertex", "vec4<f32>", "vertex" );
		}

		if ( shaderStage == "vertex" || shaderStage == "fragment" ) {
			var varyings = this.varyings;
			var vars = this.vars[shaderStage];

			for ( i in 0...varyings.length ) {
				var varying = varyings[i];

				if ( varying.needsInterpolation ) {
					var attributesSnippet = `@location(${i})`;

					if ( Type.regex( varying.type, "^(int|uint|ivec|uvec)" ) ) {
						attributesSnippet += ' @interpolate( flat )';
					}

					snippets.push( `${attributesSnippet} ${varying.name} : ${this.getType( varying.type )}` );
				} else if ( shaderStage == "vertex" && !vars.contains( varying ) ) {
					vars.push( varying );
				}
			}
		}

		var builtins = this.getBuiltins( shaderStage );

		if ( builtins != null ) snippets.push( builtins );

		var code = snippets.join( ',\n\t' );

		return shaderStage == "vertex" ? this._getWGSLStruct( "VaryingsStruct", '\t' + code ) : code;
	}

	public function getUniforms( shaderStage:String ):String {
		var uniforms = this.uniforms[shaderStage];

		var bindingSnippets:Array<String> = [];
		var bufferSnippets:Array<String> = [];
		var structSnippets:Array<String> = [];
		var uniformGroups:Map<String, { index:Int, snippets:Array<String> }> = new Map();

		var index = this.bindingsOffset[shaderStage];

		for ( uniform in uniforms ) {
			if ( uniform.type == "texture" || uniform.type == "cubeTexture" || uniform.type == "storageTexture" ) {
				var texture = uniform.node.value;

				if ( shaderStage == "fragment" && this.isUnfilterable( texture ) == false && uniform.node.isStoreTextureNode == false ) {
					if ( texture.isDepthTexture && texture.compareFunction != null ) {
						bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name}_sampler : sampler_comparison;` );
					} else {
						bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name}_sampler : sampler;` );
					}
				}

				var textureType:String;

				if ( texture.isCubeTexture ) {
					textureType = "texture_cube<f32>";
				} else if ( texture.isDataArrayTexture ) {
					textureType = "texture_2d_array<f32>";
				} else if ( texture.isDepthTexture ) {
					textureType = "texture_depth_2d";
				} else if ( texture.isVideoTexture ) {
					textureType = "texture_external";
				} else if ( uniform.node.isStoreTextureNode ) {
					var format = WebGPUTextureUtils.getFormat( texture );
					textureType = `texture_storage_2d<${format}, write>`;
				} else {
					var componentPrefix = this.getComponentTypeFromTexture( texture ).charAt( 0 );
					textureType = `texture_2d<${componentPrefix}32>`;
				}

				bindingSnippets.push( `@binding(${index++}) @group(0) var ${uniform.name} : ${textureType};` );
			} else if ( uniform.type == "buffer" || uniform.type == "storageBuffer" ) {
				var bufferNode = uniform.node;
				var bufferType = this.getType( bufferNode.bufferType );
				var bufferCount = bufferNode.bufferCount;

				var bufferCountSnippet = bufferCount > 0 ? ', ' + bufferCount : '';
				var bufferSnippet = `\t${uniform.name} : array< ${bufferType}${bufferCountSnippet} >\n`;
				var bufferAccessMode = bufferNode.isStorageBufferNode ? "storage,read_write" : "uniform";

				bufferSnippets.push( this._getWGSLStructBinding( "NodeBuffer_" + bufferNode.id, bufferSnippet, bufferAccessMode, index++ ) );
			} else {
				var vectorType = this.getType( this.getVectorType( uniform.type ) );
				var groupName = uniform.groupNode.name;

				var group = uniformGroups.get( groupName );
				if ( group == null ) {
					group = { index:index++, snippets:[] };
					uniformGroups.set( groupName, group );
				}

				group.snippets.push( `\t${uniform.name} : ${vectorType}` );
			}
		}

		for ( name in uniformGroups.keys() ) {
			var group = uniformGroups.get( name );

			structSnippets.push( this._getWGSLStructBinding( name, group.snippets.join( ',\n' ), "uniform", group.index ) );
		}

		var code = bindingSnippets.join( '\n' );
		code += bufferSnippets.join( '\n' );
		code += structSnippets.join( '\n' );

		return code;
	}

	override public function buildCode() {
		var shadersData = this.material != null ? { fragment: {}, vertex: {} } : { compute: {} };

		for ( shaderStage in shadersData.keys() ) {
			var stageData = shadersData[shaderStage];
			stageData.uniforms = this.getUniforms( shaderStage );
			stageData.attributes = this.getAttributes( shaderStage );
			stageData.varyings = this.getVaryings( shaderStage );
			stageData.structs = this.getStructs( shaderStage );
			stageData.vars = this.getVars( shaderStage );
			stageData.codes = this.getCodes( shaderStage );

			//

			var flow = '// code\n\n';
			flow += this.flowCode[shaderStage];

			var flowNodes = this.flowNodes[shaderStage];
			var mainNode = flowNodes[flowNodes.length - 1];

			var outputNode = mainNode.outputNode;
			var isOutputStruct = ( outputNode != null && outputNode.isOutputStructNode );

			for ( node in flowNodes ) {
				var flowSlotData = this.getFlowData( node );
				var slotName = node.name;

				if ( slotName != null ) {
					if ( flow.length > 0 ) flow += '\n';
					flow += `\t// flow -> ${slotName}\n\t`;
				}

				flow += `${flowSlotData.code}\n\t`;

				if ( node == mainNode && shaderStage != "compute" ) {
					flow += '// result\n\n\t';

					if ( shaderStage == "vertex" ) {
						flow += `varyings.Vertex = ${flowSlotData.result};`;
					} else if ( shaderStage == "fragment" ) {
						if ( isOutputStruct ) {
							stageData.returnType = outputNode.nodeType;
							flow += `return ${flowSlotData.result};`;
						} else {
							var structSnippet = '\t@location(0) color: vec4<f32>';

							var builtins = this.getBuiltins( "output" );

							if ( builtins != null ) structSnippet += ',\n\t' + builtins;

							stageData.returnType = "OutputStruct";
							stageData.structs += this._getWGSLStruct( "OutputStruct", structSnippet );
							stageData.structs += '\nvar<private> output : OutputStruct;\n\n';

							flow += `output.color = ${flowSlotData.result};\n\n\treturn output;`;
						}
					}
				}
			}

			stageData.flow = flow;
		}

		if ( this.material != null ) {
			this.vertexShader = this._getWGSLVertexCode( shadersData.vertex );
			this.fragmentShader = this._getWGSLFragmentCode( shadersData.fragment );
		} else {
			this.computeShader = this._getWGSLComputeCode( shadersData.compute, ( this.object.workgroupSize != null ? this.object.workgroupSize : [64] ).join( ", " ) );
		}
	}

	override public function getMethod( method:String, output:String = null ):String {
		var wgslMethod:String;

		if ( output != null ) {
			wgslMethod = this._getWGSLMethod( method + '_' + output );
		}

		if ( wgslMethod == null ) {
			wgslMethod = this._getWGSLMethod( method );
		}

		return wgslMethod != null ? wgslMethod : method;
	}

	override public function getType( type:String ):String {
		return wgslTypeLib[type] != null ? wgslTypeLib[type] : type;
	}

	override public function isAvailable( name:String ):Bool {
		return supports[name];
	}

	public function _getWGSLMethod( method:String ):String {
		if ( wgslPolyfill[method] != null ) {
			this._include( method );
		}

		return wgslMethods[method];
	}

	public function _include( name:String ):CodeNode {
		var codeNode = wgslPolyfill[name];
		codeNode.build( this );

		if ( this.currentFunctionNode != null ) {
			this.currentFunctionNode.includes.push( codeNode );
		}

		return codeNode;
	}

	public function _getWGSLVertexCode( shaderData:Dynamic ):String {
		return `${this.getSignature()}

// uniforms
${shaderData.uniforms}

// varyings
${shaderData.varyings}
var<private> varyings : VaryingsStruct;

// codes
${shaderData.codes}

@vertex
fn main(${shaderData.attributes}) -> VaryingsStruct {

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

	return varyings;

}
`;
	}

	public function _getWGSLFragmentCode( shaderData:Dynamic ):String {
		return `${this.getSignature()}

// uniforms
${shaderData.uniforms}

// structs
${shaderData.structs}

// codes
${shaderData.codes}

@fragment
fn main(${shaderData.varyings}) -> ${shaderData.returnType} {

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

}
`;
	}

	public function _getWGSLComputeCode( shaderData:Dynamic, workgroupSize:String ):String {
		return `${this.getSignature()}
// system
var<private> instanceIndex : u32;

// uniforms
${shaderData.uniforms}

// codes
${shaderData.codes}

@compute @workgroup_size(${workgroupSize})
fn main(${shaderData.attributes}) {

	// system
	instanceIndex = id.x;

	// vars
	${shaderData.vars}

	// flow
	${shaderData.flow}

}
`;
	}

	public function _getWGSLStruct( name:String, vars:String ):String {
		return `
struct ${name} {
${vars}
};`;
	}

	public function _getWGSLStructBinding( name:String, vars:String, access:String, binding:Int = 0, group:Int = 0 ):String {
		var structName = name + "Struct";
		var structSnippet = this._getWGSLStruct( structName, vars );

		return `${structSnippet}
@binding(${binding}) @group(${group})
var<${access}> ${name} : ${structName};`;
	}

}

// GPUShaderStage is not defined in browsers not supporting WebGPU
#if webgpu
var GPUShaderStage = WebGPUShaderStage;
#end

var gpuShaderStageLib:Map<String, Int> = {
	"vertex": GPUShaderStage != null ? GPUShaderStage.VERTEX : 1,
	"fragment": GPUShaderStage != null ? GPUShaderStage.FRAGMENT : 2,
	"compute": GPUShaderStage != null ? GPUShaderStage.COMPUTE : 4
};

var supports:Map<String, Bool> = {
	"instance": true,
	"storageBuffer": true
};

var wgslFnOpLib:Map<String, String> = {
	"^^": "threejs_xor"
};

var wgslTypeLib:Map<String, String> = {
	"float": "f32",
	"int": "i32",
	"uint": "u32",
	"bool": "bool",
	"color": "vec3<f32>",

	"vec2": "vec2<f32>",
	"ivec2": "vec2<i32>",
	"uvec2": "vec2<u32>",
	"bvec2": "vec2<bool>",

	"vec3": "vec3<f32>",
	"ivec3": "vec3<i32>",
	"uvec3": "vec3<u32>",
	"bvec3": "vec3<bool>",

	"vec4": "vec4<f32>",
	"ivec4": "vec4<i32>",
	"uvec4": "vec4<u32>",
	"bvec4": "vec4<bool>",

	"mat2": "mat2x2<f32>",
	"imat2": "mat2x2<i32>",
	"umat2": "mat2x2<u32>",
	"bmat2": "mat2x2<bool>",

	"mat3": "mat3x3<f32>",
	"imat3": "mat3x3<i32>",
	"umat3": "mat3x3<u32>",
	"bmat3": "mat3x3<bool>",

	"mat4": "mat4x4<f32>",
	"imat4": "mat4x4<i32>",
	"umat4": "mat4x4<u32>",
	"bmat4": "mat4x4<bool>"
};

var wgslMethods:Map<String, String> = {
	"dFdx": "dpdx",
	"dFdy": "- dpdy",
	"mod_float": "threejs_mod_float",
	"mod_vec2": "threejs_mod_vec2",
	"mod_vec3": "threejs_mod_vec3",
	"mod_vec4": "threejs_mod_vec4",
	"equals_bool": "threejs_equals_bool",
	"equals_bvec2": "threejs_equals_bvec2",
	"equals_bvec3": "threejs_equals_bvec3",
	"equals_bvec4": "threejs_equals_bvec4",
	"lessThanEqual": "threejs_lessThanEqual",
	"greaterThan": "threejs_greaterThan",
	"inversesqrt": "inverseSqrt",
	"bitcast": "bitcast<f32>"
};

var wgslPolyfill:Map