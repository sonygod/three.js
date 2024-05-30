import haxe.io.Bytes;
import js.Browser;
import js.html.Document;
import js.html.Window;
import js.html.HTMLElement;
import js.html.HTMLCanvasElement;
import js.html.HTMLImageElement;
import js.html.HTMLVideoElement;
import js.html.HTMLAudioElement;
import js.html.HTMLInputElement;
import js.html.HTMLSelectElement;
import js.html.HTMLTextAreaElement;
import js.html.HTMLDivElement;
import js.html.HTMLBodyElement;
import js.html.HTMLHeadingElement;
import js.html.HTMLParagraphElement;
import js.html.HTMLAnchorElement;
import js.html.HTMLImageElement;
import js.html.HTMLButtonElement;

class WGSLNodeBuilder {
	public function new(object:Dynamic, renderer:Dynamic, ?scene:Dynamic) {
		super(object, renderer, new WGSLNodeParser(), scene);
		this.uniformGroups = {};
		this.builtins = {};
	}

	public function needsColorSpaceToLinear(texture:Dynamic):Bool {
		return texture.isVideoTexture && texture.colorSpace != NoColorSpace;
	}

	public function _generateTextureSample(texture:Dynamic, textureProperty:String, uvSnippet:String, depthSnippet:Dynamic, shaderStage:String = this.shaderStage):String {
		if (shaderStage == 'fragment') {
			if (depthSnippet != null) {
				return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${depthSnippet})';
			} else {
				return 'textureSample(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet})';
			}
		} else {
			return this.generateTextureLod(texture, textureProperty, uvSnippet);
		}
	}

	public function _generateVideoSample(textureProperty:String, uvSnippet:String, shaderStage:String = this.shaderStage):String {
		if (shaderStage == 'fragment') {
			return 'textureSampleBaseClampToEdge(${textureProperty}, ${textureProperty}_sampler, vec2<f32>(${uvSnippet}.x, 1.0 - ${uvSnippet}.y))';
		} else {
			console.error('WebGPURenderer: THREE.VideoTexture does not support ${shaderStage} shader.');
		}
	}

	public function _generateTextureSampleLevel(texture:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:Dynamic, shaderStage:String = this.shaderStage):String {
		if (shaderStage == 'fragment' && !this.isUnfilterable(texture)) {
			return 'textureSampleLevel(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${levelSnippet})';
		} else {
			return this.generateTextureLod(texture, textureProperty, uvSnippet, levelSnippet);
		}
	}

	public function generateTextureLod(texture:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String = '0'):String {
		this._include('repeatWrapping');
		const dimension = 'textureDimensions(${textureProperty}, 0)';
		return 'textureLoad(${textureProperty}, threejs_repeatWrapping(${uvSnippet}, ${dimension}), i32(${levelSnippet}))';
	}

	public function generateTextureLoad(texture:Dynamic, textureProperty:String, uvIndexSnippet:String, depthSnippet:Dynamic, levelSnippet:String = '0u'):String {
		if (depthSnippet != null) {
			return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${depthSnippet}, ${levelSnippet})';
		} else {
			return 'textureLoad(${textureProperty}, ${uvIndexSnippet}, ${levelSnippet})';
		}
	}

	public function generateTextureStore(texture:Dynamic, textureProperty:String, uvIndexSnippet:String, valueSnippet:String):String {
		return 'textureStore(${textureProperty}, ${uvIndexSnippet}, ${valueSnippet})';
	}

	public function isUnfilterable(texture:Dynamic):Bool {
		return this.getComponentTypeFromTexture(texture) != 'float' || (texture.isDataTexture && texture.type == FloatType);
	}

	public function generateTexture(texture:Dynamic, textureProperty:String, uvSnippet:String, depthSnippet:Dynamic, shaderStage:String = this.shaderStage):String {
		var snippet:String;
		if (texture.isVideoTexture) {
			snippet = this._generateVideoSample(textureProperty, uvSnippet, shaderStage);
		} else if (this.isUnfilterable(texture)) {
			snippet = this.generateTextureLod(texture, textureProperty, uvSnippet, '0', depthSnippet, shaderStage);
		} else {
			snippet = this._generateTextureSample(texture, textureProperty, uvSnippet, depthSnippet, shaderStage);
		}
		return snippet;
	}

	public function generateTextureGrad(texture:Dynamic, textureProperty:String, uvSnippet:String, gradSnippet:Array<String>, depthSnippet:Dynamic, shaderStage:String = this.shaderStage):String {
		if (shaderStage == 'fragment') {
			// TODO handle i32 or u32 --> uvSnippet, array_index: A, ddx, ddy
			return 'textureSampleGrad(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${gradSnippet[0]}, ${gradSnippet[1]})';
		} else {
			console.error('WebGPURenderer: THREE.TextureNode.gradient() does not support ${shaderStage} shader.');
		}
	}

	public function generateTextureCompare(texture:Dynamic, textureProperty:String, uvSnippet:String, compareSnippet:String, depthSnippet:Dynamic, shaderStage:String = this.shaderStage):String {
		if (shaderStage == 'fragment') {
			return 'textureSampleCompare(${textureProperty}, ${textureProperty}_sampler, ${uvSnippet}, ${compareSnippet})';
		} else {
			console.error('WebGPURenderer: THREE.DepthTexture.compareFunction() does not support ${shaderStage} shader.');
		}
	}

	public function generateTextureLevel(texture:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String, depthSnippet:Dynamic, shaderStage:String = this.shaderStage):String {
		var snippet:String;
		if (texture.isVideoTexture) {
			snippet = this._generateVideoSample(textureProperty, uvSnippet, shaderStage);
		} else {
			snippet = this._generateTextureSampleLevel(texture, textureProperty, uvSnippet, levelSnippet, depthSnippet, shaderStage);
		}
		return snippet;
	}

	public function getPropertyName(node:Dynamic, shaderStage:String = this.shaderStage):String {
		if (node.isNodeVarying && node.needsInterpolation) {
			if (shaderStage == 'vertex') {
				return 'varyings.' + node.name;
			}
		} else if (node.isNodeUniform) {
			var name = node.name;
			var type = node.type;
			if (type == 'texture' || type == 'cubeTexture' || type == 'storageTexture') {
				return name;
			} else if (type == 'buffer' || type == 'storageBuffer') {
				return 'NodeBuffer_' + node.id + '.' + name;
			} else {
				return node.groupNode.name + '.' + name;
			}
		}
		return super.getPropertyName(node);
	}

	public function _getUniformGroupCount(shaderStage:String):Int {
		return Reflect.field(this.uniforms, shaderStage).length;
	}

	public function getFunctionOperator(op:String):String {
		var fnOp = wgslFnOpLib[op];
		if (fnOp != null) {
			this._include(fnOp);
			return fnOp;
		}
		return null;
	}

	public function getUniformFromNode(node:Dynamic, type:String, shaderStage:String, name:String = null):Dynamic {
		var uniformNode = super.getUniformFromNode(node, type, shaderStage, name);
		var nodeData = this.getDataFromNode(node, shaderStage, this.globalCache);
		if (nodeData.uniformGPU == null) {
			var uniformGPU:Dynamic;
			var bindings = this.bindings[shaderStage];
			if (type == 'texture' || type == 'cubeTexture' || type == 'storageTexture') {
				var texture:Dynamic;
				if (type == 'texture' || type == 'storageTexture') {
					texture = new NodeSampledTexture(uniformNode.name, uniformNode.node);
				} else if (type == 'cubeTexture') {
					texture = new NodeSampledCubeTexture(uniformNode.name, uniformNode.node);
				}
				texture.store = node.isStoreTextureNode;
				texture.setVisibility(gpuShaderStageLib[shaderStage]);
				if (shaderStage == 'fragment' && !this.isUnfilterable(node.value) && !texture.store) {
					var sampler = new NodeSampler(uniformNode.name + '_sampler', uniformNode.node);
					sampler.setVisibility(gpuShaderStageLib[shaderStage]);
					bindings.push(sampler, texture);
					uniformGPU = [sampler, texture];
				} else {
					bindings.push(texture);
					uniformGPU = [texture];
				}
			} else if (type == 'buffer' || type == 'storageBuffer') {
				var bufferClass = if (type == 'storageBuffer') NodeStorageBuffer else NodeUniformBuffer;
				var buffer = new bufferClass(node);
				buffer.setVisibility(gpuShaderStageLib[shaderStage]);
				bindings.push(buffer);
				uniformGPU = buffer;
			} else {
				var group = node.groupNode;
				var groupName = group.name;
				var uniformsStage = this.uniformGroups[shaderStage] || (this.uniformGroups[shaderStage] = {});
				var uniformsGroup = uniformsStage[groupName];
				if (uniformsGroup == null) {
					uniformsGroup = new NodeUniformsGroup(groupName, group);
					uniformsGroup.setVisibility(gpuShaderStageLib[shaderStage]);
					uniformsStage[groupName] = uniformsGroup;
					bindings.push(uniformsGroup);
				}
				uniformGPU = this.getNodeUniform(uniformNode, type);
				uniformsGroup.addUniform(uniformGPU);
			}
			nodeData.uniformGPU = uniformGPU;
			if (shaderStage == 'vertex') {
				this.bindingsOffset['fragment'] = bindings.length;
			}
		}
		return uniformNode;
	}

	public function isReference(type:String):Bool {
		return super.isReference(type) || type == 'texture_2d' || type == 'texture_cube' || type == 'texture_depth_2d' || type == 'texture_storage_2d';
	}

	public function getBuiltin(name:String, property:String, type:String, shaderStage:String = this.shaderStage):String {
		var map = this.builtins[shaderStage] || (this.builtins[shaderStage] = new Map());
		if (!map.exists(name)) {
			map.set(name, {name, property, type});
		}
		return property;
	}

	public function getVertexIndex():String {
		if (this.shaderStage == 'vertex') {
			return this.getBuiltin('vertex_index', 'vertexIndex', 'u32', 'attribute');
		}
		return 'vertexIndex';
	}

	public function buildFunctionCode(shaderNode:Dynamic):String {
		var layout = shaderNode.layout;
		var flowData = this.flowShaderNode(shaderNode);
		var parameters = [];
		var inputs = layout.inputs;
		for (input in inputs) {
			parameters.push(input.name + ' : ' + this.getType(input.type));
		}
		var code = 'fn ${layout.name}(${parameters.join(', ')}) -> ${this.getType(layout.type)} {\n${flowData.vars}\n${flowData.code}\n\treturn ${flowData.result};\n}';
		return code;
	}

	public function getInstanceIndex():String {
		if (this.shaderStage == 'vertex') {
			return this.getBuiltin('instance_index', 'instanceIndex', 'u32', 'attribute');
		}
		return 'instanceIndex';
	}

	public function getFrontFacing():String {
		return this.getBuiltin('front_facing', 'isFront', 'bool');
	}

	public function getFragCoord():String {
		return this.getBuiltin('position', 'fragCoord', 'vec4<f32>') + '.xyz';
	}

	public function getFragDepth():String {
		return 'output.' + this.getBuiltin('frag_depth', 'depth', 'f32', 'output');
	}

	public function isFlipY():Bool {
		return false;
	}

	public function getBuiltins(shaderStage:String):String {
		var snippets = [];
		var builtins = this.builtins[shaderStage];
		if (builtins != null) {
			for (builtin in builtins) {
				var {name, property, type} = builtin;
				snippets.push('@builtin(${name}) ${property} : ${type}');
			}
		}
		return snippets.join(',\n\t');
	}

	public function getAttributes(shaderStage:String):String {
		var snippets = [];
		if (shaderStage == 'compute') {
			this.getBuiltin('global_invocation_id', 'id', 'vec3<u32>', 'attribute');
		}
		if (shaderStage == 'vertex' || shaderStage == 'compute') {
			var builtins = this.getBuiltins('attribute');
			if (builtins != null) snippets.push(builtins);
			var attributes = this.getAttributesArray();
			for (index in 0...attributes.length) {
				var attribute = attributes[index];
				var name = attribute.name;
				var type = this.getType(attribute.type);
				snippets.push('@location(${index}) ${name} : ${type}');
			}
		}
		return snippets.join(',\n\t');
	}

	public function getStructMembers(struct:Dynamic):String {
		var snippets = [];
		var members = struct.getMemberTypes();
		for (index in 0...members.length) {
			var member = members[index];
			snippets.push('\t@location(${index}) m${index} : ${member}<f32>');
		}
		return snippets.join(',\n');
	}

	public function getStructs(shaderStage:String):String {
		var snippets = [];
		var structs = this.structs[shaderStage];
		for (index in 0...structs.length) {
			var struct = structs[index];
			var name = struct.name;
			var snippet = '\struct ${name} {\n';
			snippet += this.getStructMembers(struct);
			snippet += '\n}';
			snippets.push(snippet);
		}
		return snippets.join('\n\n');
	}

	public function getVar(type:Dynamic, name:String):String {
		return 'var ${name} : ${this.getType(type)}';
	}

	public function getVars(shaderStage:String):String {
		var snippets = [];
		var vars = this.vars[shaderStage];
		if (vars != null) {
			for (variable in vars) {
				snippets.push('\t${this.getVar(variable.type, variable.name)};');
			}
		}
		return '\n${snippets.join('\n')}\n';
	}

	public function getVaryings(shaderStage:String):String {
		var snippets = [];
		if (shaderStage == 'vertex') {
			this.getBuiltin('position', 'Vertex', 'vec4<f32>', 'vertex');
		}
		if (shaderStage == 'vertex' || shaderStage == 'fragment') {
			var varyings = this.varyings;
			var vars = this.vars[shaderStage];
			for (index in 0...varyings.length) {
				var varying = varyings[index];
				if (varying.needsInterpolation) {
					var attributesSnippet = '@location(${index})';
					if (/(int|uint|ivec|uvec)/.test(varying.type)) {
						attributesSnippet += ' @interpolate(flat)';
					}
					snippets.push('${attributesSnippet} ${varying.name} : ${this.getType(varying.type)}');
				} else if (shaderStage == 'vertex' && (vars == null || !vars.includes(varying))) {
					if (vars == null) vars = [];
					vars.push(varying);
				}
			}
		}
		var builtins = this.getBuiltins(shaderStage);
		if (builtins != null) snippets.push(builtins);
		var code = snippets.join(',\n\t');