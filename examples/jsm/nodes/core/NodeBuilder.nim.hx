import NodeUniform from './NodeUniform.hx';
import NodeAttribute from './NodeAttribute.hx';
import NodeVarying from './NodeVarying.hx';
import NodeVar from './NodeVar.hx';
import NodeCode from './NodeCode.hx';
import NodeKeywords from './NodeKeywords.hx';
import NodeCache from './NodeCache.hx';
import ParameterNode from './ParameterNode.hx';
import FunctionNode from '../code/FunctionNode.hx';
import { createNodeMaterialFromType, default as NodeMaterial } from '../materials/NodeMaterial.hx';
import { NodeUpdateType, defaultBuildStages, shaderStages } from './constants.hx';

import {
	FloatNodeUniform, Vector2NodeUniform, Vector3NodeUniform, Vector4NodeUniform,
	ColorNodeUniform, Matrix3NodeUniform, Matrix4NodeUniform
} from '../../renderers/common/nodes/NodeUniform.hx';

import { REVISION, RenderTarget, Color, Vector2, Vector3, Vector4, IntType, UnsignedIntType, Float16BufferAttribute } from 'three';

import { stack } from './StackNode.hx';
import { getCurrentStack, setCurrentStack } from '../shadernode/ShaderNode.hx';

import CubeRenderTarget from '../../renderers/common/CubeRenderTarget.hx';
import ChainMap from '../../renderers/common/ChainMap.hx';

import PMREMGenerator from '../../renderers/common/extras/PMREMGenerator.hx';

class NodeBuilder {

	public var object:Dynamic;
	public var renderer:Dynamic;
	public var parser:Dynamic;
	public var scene:Dynamic;
	public var material:Dynamic;
	public var geometry:Dynamic;
	public var nodes:Array<Dynamic>;
	public var updateNodes:Array<Dynamic>;
	public var updateBeforeNodes:Array<Dynamic>;
	public var hashNodes:Map<String, Dynamic>;
	public var lightsNode:Dynamic;
	public var environmentNode:Dynamic;
	public var fogNode:Dynamic;
	public var clippingContext:Dynamic;
	public var vertexShader:Dynamic;
	public var fragmentShader:Dynamic;
	public var computeShader:Dynamic;
	public var flowNodes:Map<String, Array<Dynamic>>;
	public var flowCode:Map<String, String>;
	public var uniforms:Map<String, Array<Dynamic>>;
	public var structs:Map<String, Array<Dynamic>>;
	public var bindings:Map<String, Array<Dynamic>>;
	public var bindingsOffset:Map<String, Int>;
	public var bindingsArray:Dynamic;
	public var attributes:Array<Dynamic>;
	public var bufferAttributes:Array<Dynamic>;
	public var varyings:Array<Dynamic>;
	public var codes:Map<String, Array<Dynamic>>;
	public var vars:Map<String, Array<Dynamic>>;
	public var flow:Map<String, String>;
	public var chaining:Array<Dynamic>;
	public var stack:Dynamic;
	public var stacks:Array<Dynamic>;
	public var tab:String;
	public var currentFunctionNode:Dynamic;
	public var context:Map<String, Dynamic>;
	public var cache:Dynamic;
	public var globalCache:Dynamic;
	public var flowsData:Map<Dynamic, Map<String, Dynamic>>;
	public var shaderStage:Dynamic;
	public var buildStage:Dynamic;

	public function new(object:Dynamic, renderer:Dynamic, parser:Dynamic, scene:Dynamic = null, material:Dynamic = null) {
		this.object = object;
		this.material = material || (object && object.material) || null;
		this.geometry = (object && object.geometry) || null;
		this.renderer = renderer;
		this.parser = parser;
		this.scene = scene;

		this.nodes = [];
		this.updateNodes = [];
		this.updateBeforeNodes = [];
		this.hashNodes = new Map();

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

		this.flowsData = new Map();

		this.shaderStage = null;
		this.buildStage = null;
	}

	public function createRenderTarget(width:Int, height:Int, options:Dynamic):RenderTarget {
		return new RenderTarget(width, height, options);
	}

	public function createCubeRenderTarget(size:Int, options:Dynamic):CubeRenderTarget {
		return new CubeRenderTarget(size, options);
	}

	public function createPMREMGenerator():PMREMGenerator {
		return new PMREMGenerator(this.renderer);
	}

	public function includes(node:Dynamic):Bool {
		return this.nodes.includes(node);
	}

	private function _getSharedBindings(bindings:Array<Dynamic>):Array<Dynamic> {
		var shared = [];

		for (binding in bindings) {
			if (binding.shared === true) {
				var nodes = binding.getNodes();
				var sharedBinding = uniformsGroupCache.get(nodes);

				if (sharedBinding === undefined) {
					uniformsGroupCache.set(nodes, binding);
					sharedBinding = binding;
				}

				shared.push(sharedBinding);
			} else {
				shared.push(binding);
			}
		}

		return shared;
	}

	public function getBindings():Array<Dynamic> {
		var bindingsArray = this.bindingsArray;

		if (bindingsArray === null) {
			var bindings = this.bindings;
			this.bindingsArray = bindingsArray = this._getSharedBindings((this.material !== null) ? [ ...bindings.vertex, ...bindings.fragment ] : bindings.compute);
		}

		return bindingsArray;
	}

	public function setHashNode(node:Dynamic, hash:String):Void {
		this.hashNodes[hash] = node;
	}

	public function addNode(node:Dynamic):Void {
		if (this.nodes.includes(node) === false) {
			this.nodes.push(node);
			this.setHashNode(node, node.getHash(this));
		}
	}

	public function buildUpdateNodes():Void {
		for (node in this.nodes) {
			var updateType = node.getUpdateType();
			var updateBeforeType = node.getUpdateBeforeType();

			if (updateType !== NodeUpdateType.NONE) {
				this.updateNodes.push(node.getSelf());
			}

			if (updateBeforeType !== NodeUpdateType.NONE) {
				this.updateBeforeNodes.push(node);
			}
		}
	}

	public var currentNode(get, null):Dynamic {
		return this.chaining[this.chaining.length - 1];
	}

	public function addChain(node:Dynamic):Void {
		this.chaining.push(node);
	}

	public function removeChain(node:Dynamic):Void {
		var lastChain = this.chaining.pop();

		if (lastChain !== node) {
			throw new Error('NodeBuilder: Invalid node chaining!');
		}
	}

	public function getMethod(method:Dynamic):Dynamic {
		return method;
	}

	public function getNodeFromHash(hash:String):Dynamic {
		return this.hashNodes[hash];
	}

	public function addFlow(shaderStage:String, node:Dynamic):Dynamic {
		this.flowNodes[shaderStage].push(node);
		return node;
	}

	public function setContext(context:Map<String, Dynamic>):Void {
		this.context = context;
	}

	public function getContext():Map<String, Dynamic> {
		return this.context;
	}

	public function setCache(cache:Dynamic):Void {
		this.cache = cache;
	}

	public function getCache():Dynamic {
		return this.cache;
	}

	public function isAvailable(/*name*/):Bool {
		return false;
	}

	public function getVertexIndex():Void {
		console.warn('Abstract function.');
	}

	public function getInstanceIndex():Void {
		console.warn('Abstract function.');
	}

	public function getFrontFacing():Void {
		console.warn('Abstract function.');
	}

	public function getFragCoord():Void {
		console.warn('Abstract function.');
	}

	public function isFlipY():Bool {
		return false;
	}

	public function generateTexture(/* texture, textureProperty, uvSnippet */):Void {
		console.warn('Abstract function.');
	}

	public function generateTextureLod(/* texture, textureProperty, uvSnippet, levelSnippet */):Void {
		console.warn('Abstract function.');
	}

	public function generateConst(type:String, value:Dynamic = null):String {
		if (value === null) {
			if (type === 'float' || type === 'int' || type === 'uint') value = 0;
			else if (type === 'bool') value = false;
			else if (type === 'color') value = new Color();
			else if (type === 'vec2') value = new Vector2();
			else if (type === 'vec3') value = new Vector3();
			else if (type === 'vec4') value = new Vector4();
		}

		if (type === 'float') return toFloat(value);
		if (type === 'int') return `${Math.round(value)}`;
		if (type === 'uint') return value >= 0 ? `${Math.round(value)}u` : '0u';
		if (type === 'bool') return value ? 'true' : 'false';
		if (type === 'color') return `${this.getType('vec3')}( ${toFloat(value.r)}, ${toFloat(value.g)}, ${toFloat(value.b)} )`;

		var typeLength = this.getTypeLength(type);

		var componentType = this.getComponentType(type);

		var generateConst = function(value:Dynamic):String {
			return this.generateConst(componentType, value);
		};

		if (typeLength === 2) {
			return `${this.getType(type)}( ${generateConst(value.x)}, ${generateConst(value.y)} )`;
		} else if (typeLength === 3) {
			return `${this.getType(type)}( ${generateConst(value.x)}, ${generateConst(value.y)}, ${generateConst(value.z)} )`;
		} else if (typeLength === 4) {
			return `${this.getType(type)}( ${generateConst(value.x)}, ${generateConst(value.y)}, ${generateConst(value.z)}, ${generateConst(value.w)} )`;
		} else if (typeLength > 4 && value && (value.isMatrix3 || value.isMatrix4)) {
			return `${this.getType(type)}( ${value.elements.map(generateConst).join(', ')} )`;
		} else if (typeLength > 4) {
			return `${this.getType(type)}()`;
		}

		throw new Error(`NodeBuilder: Type '${type}' not found in generate constant attempt.`);
	}

	public function getType(type:String):String {
		if (type === 'color') return 'vec3';
		return type;
	}

	public function generateMethod(method:Dynamic):Dynamic {
		return method;
	}

	public function hasGeometryAttribute(name:String):Bool {
		return this.geometry && this.geometry.getAttribute(name) !== undefined;
	}

	public function getAttribute(name:String, type:String):Dynamic {
		var attributes = this.attributes;

		for (attribute in attributes) {
			if (attribute.name === name) {
				return attribute;
			}
		}

		var attribute = new NodeAttribute(name, type);
		attributes.push(attribute);
		return attribute;
	}

	public function getPropertyName(node:Dynamic, shaderStage:String):String {
		return node.name;
	}

	public function isVector(type:String):Bool {
		return /vec\d/.test(type);
	}

	public function isMatrix(type:String):Bool {
		return /mat\d/.test(type);
	}

	public function isReference(type:String):Bool {
		return type === 'void' || type === 'property' || type === 'sampler' || type === 'texture' || type === 'cubeTexture' || type === 'storageTexture';
	}

	public function needsColorSpaceToLinear(/*texture*/):Bool {
		return false;
	}

	public function getComponentTypeFromTexture(texture:Dynamic):String {
		var type = texture.type;

		if (texture.isDataTexture) {
			if (type === IntType) return 'int';
			if (type === UnsignedIntType) return 'uint';
		}

		return 'float';
	}

	public function getComponentType(type:String):String {
		type = this.getVectorType(type);

		if (type === 'float' || type === 'bool' || type === 'int' || type === 'uint') return type;

		var componentType = /(b|i|u|)(vec|mat)([2-4])/.exec(type);

		if (componentType === null) return null;

		if (componentType[1] === 'b') return 'bool';
		if (componentType[1] === 'i') return 'int';
		if (componentType[1] === 'u') return 'uint';

		return 'float';
	}

	public function getVectorType(type:String):String {
		if (type === 'color') return 'vec3';
		if (type === 'texture' || type === 'cubeTexture' || type === 'storageTexture') return 'vec4';
		return type;
	}

	public function getTypeFromLength(length:Int, componentType:String = 'float'):String {
		if (length === 1) return componentType;

		var baseType = typeFromLength.get(length);
		var prefix = componentType === 'float' ? '' : componentType[0];

		return prefix + baseType;
	}

	public function getTypeFromArray(array:Dynamic):String {
		return typeFromArray.get(array.constructor);
	}

	public function getTypeFromAttribute(attribute:Dynamic):String {
		var dataAttribute = attribute;

		if (attribute.isInterleavedBufferAttribute) dataAttribute = attribute.data;

		var array = dataAttribute.array;
		var itemSize = attribute.itemSize;
		var normalized = attribute.normalized;

		var arrayType;

		if (! (attribute instanceof Float16BufferAttribute) && normalized !== true) {
			arrayType = this.getTypeFromArray(array);
		}

		return this.getTypeFromLength(itemSize, arrayType);
	}

	public function getTypeLength(type:String):Int {
		var vecType = this.getVectorType(type);
		var vecNum = /vec([2-4])/.exec(vecType);

		if (vecNum !== null) return Std.parseInt(vecNum[1]);
		if (vecType === 'float' || vecType === 'bool' || vecType === 'int' || vecType === 'uint') return 1;
		if (/mat2/.test(type) === true) return 4;
		if (/mat3/.test(type) === true) return 9;
		if (/mat4/.test(type) === true) return 16;

		return 0;
	}

	public function getVectorFromMatrix(type:String):String {
		return type.replace('mat', 'vec');
	}

	public function changeComponentType(type:String, newComponentType:String):String {
		return this.getTypeFromLength(this.getTypeLength(type), newComponentType);
	}

	public function getIntegerType(type:String):String {
		var componentType = this.getComponentType(type);

		if (componentType === 'int' || componentType === 'uint') return type;

		return this.changeComponentType(type, 'int');
	}

	public function addStack():Dynamic {
		this.stack = stack(this.stack);

		this.stacks.push(getCurrentStack() || this.stack);
		setCurrentStack(this.stack);

		return this.stack;
	}

	public function removeStack():Dynamic {
		var lastStack = this.stack;
		this.stack = lastStack.parent;

		setCurrentStack(this.stacks.pop());

		return lastStack;
	}

	public function getDataFromNode(node:Dynamic, shaderStage:String = this.shaderStage, cache:Dynamic = null):Map<String, Dynamic> {
		cache = cache === null ? (node.isGlobal(this) ? this.globalCache : this.cache) : cache;

		var nodeData = cache.getNodeData(node);

		if (nodeData === undefined) {
			nodeData = {};
			cache.setNodeData(node, nodeData);
		}

		if (nodeData[shaderStage] === undefined) nodeData[shaderStage] = {};

		return nodeData[shaderStage];
	}

	public function getNodeProperties(node:Dynamic, shaderStage:String = 'any'):Map<String, Dynamic> {
		var nodeData = this.getDataFromNode(node, shaderStage);

		return nodeData.properties || (nodeData.properties = { outputNode: null });
	}

	public function getBufferAttributeFromNode(node:Dynamic, type:String):Dynamic {
		var nodeData = this.getDataFromNode(node);

		var bufferAttribute = nodeData.bufferAttribute;

		if (bufferAttribute === undefined) {
			var index = this.uniforms.index ++;

			bufferAttribute = new NodeAttribute('nodeAttribute' + index, type, node);

			this.bufferAttributes.push(bufferAttribute);

			nodeData.bufferAttribute = bufferAttribute;
		}

		return bufferAttribute;
	}

	public function getStructTypeFromNode(node:Dynamic, shaderStage:String = this.shaderStage):Dynamic {
		var nodeData = this.getDataFromNode(node, shaderStage);

		if (nodeData.structType === undefined) {
			var index = this.structs.index ++;

			node.name = 'StructType' + index;
			this.structs[shaderStage].push(node);

			nodeData.structType = node;
		}

		return node;
	}

	public function getUniformFromNode(node:Dynamic, type:String, shaderStage:String = this.shaderStage, name:String = null):Dynamic {
		var nodeData = this.getDataFromNode(node, shaderStage, this.globalCache);

		var nodeUniform = nodeData.uniform;

		if (nodeUniform === undefined) {
			var index = this.uniforms.index ++;

			nodeUniform = new NodeUniform(name || ('nodeUniform' + index), type, node);

			this.uniforms[shaderStage].push(nodeUniform);

			nodeData.uniform = nodeUniform;
		}

		return nodeUniform;
	}

	public function getVarFromNode(node:Dynamic, name:String = null, type:String = node.getNodeType(this), shaderStage:String = this.shaderStage):Dynamic {
		var nodeData = this.getDataFromNode(node, shaderStage);

		var nodeVar = nodeData.variable;

		if (nodeVar === undefined) {
			var vars = this.vars[shaderStage] || (this.vars[shaderStage] = []);

			if (name === null) name = 'nodeVar' + vars.length;

			nodeVar = new NodeVar(name, type);

			vars.push(nodeVar);

			nodeData.variable = nodeVar;
		}

		return nodeVar;
	}

	public function getVaryingFromNode(node:Dynamic, name:String = null, type:String = node.getNodeType(this)):Dynamic {
		var nodeData = this.getDataFromNode(node, 'any');

		var nodeVarying = nodeData.varying;

		if (nodeVarying === undefined) {
			var varyings = this.varyings;
			var index = varyings.length;

			if (name === null) name = 'nodeVarying' + index;

			nodeVarying = new NodeVarying(name, type);

			varyings.push(nodeVarying);

			nodeData.varying = nodeVarying;
		}

		return nodeVarying;
	}

	public function getCodeFromNode(node:Dynamic, type:String, shaderStage:String = this.shaderStage):Dynamic {
		var nodeData = this.getDataFromNode(node);

		var nodeCode = nodeData.code;

		if (nodeCode === undefined) {
			var codes = this.codes[shaderStage] || (this.codes[shaderStage] = []);
			var index = codes.length;

			nodeCode = new NodeCode('nodeCode' + index, type);

			codes.push(nodeCode);

			nodeData.code = nodeCode;
		}

		return nodeCode;
	}

	public function addLineFlowCode(code:String):Dynamic {
		if (code === '') return this;

		code = this.tab + code;

		if (! /;\s*$/.test(code)) {
			code = code + ';\n';
		}

		this.flow.code += code;

		return this;
	}

	public function addFlowCode(code:String):Dynamic {
		this.flow.code += code;
		return this;
	}

	public function addFlowTab():Dynamic {
		this.tab += '\t';
		return this;
	}

	public function removeFlowTab():Dynamic {
		this.tab = this.tab.slice(0, -1);
		return this;
	}

	public function getFlowData(node/*, shaderStage*/):Map<String, Dynamic> {
		return this.flowsData.get(node);
	}

	public function flowNode(node:Dynamic):Map<String, Dynamic> {
		var output = node.getNodeType(this);

		var flowData = this.flowChildNode(node, output);

		this.flowsData.set(node, flowData);

		return flowData;
	}

	public function buildFunctionNode(shaderNode:Dynamic):FunctionNode {
		var fn = new FunctionNode();

		var previous = this.currentFunctionNode;

		this.currentFunctionNode = fn;

		fn.code = this.buildFunctionCode(shaderNode);

		this.currentFunctionNode = previous;

		return fn;
	}

	public function flowShaderNode(shaderNode:Dynamic):Map<String, Dynamic> {
		var layout = shaderNode.layout;

		var inputs;

		if (shaderNode.isArrayInput) {
			inputs = [];

			for (input in layout.inputs) {
				inputs.push(new ParameterNode(input.type, input.name));
			}
		} else {
			inputs = {};

			for (input in layout.inputs) {
				inputs[input.name] = new ParameterNode(input.type, input.name);
			}
		}

		//

		shaderNode.layout = null;

		var callNode = shaderNode.call(inputs);
		var flowData = this.flowStagesNode(callNode, layout.type);

		shaderNode.layout = layout;

		return flowData;
	}

	public function flowStagesNode(node:Dynamic, output:String = null):Map<String, Dynamic> {
		var previousFlow = this.flow;
		var previousVars = this.vars;
		var previousBuildStage = this.buildStage;

		var flow = {
			code: ''
		};

		this.flow = flow;
		this.vars = {};

		for (buildStage in defaultBuildStages) {
			this.setBuildStage(buildStage);

			flow.result = node.build(this, output);
		}

		flow.vars = this.getVars(this.shaderStage);

		this.flow = previousFlow;
		this.vars = previousVars;
		this.setBuildStage(previousBuildStage);

		return flow;
	}

	public function getFunctionOperator():Dynamic {
		return null;
	}

	public function flowChildNode(node:Dynamic, output:String = null):Map<String, Dynamic> {
		var previousFlow = this.flow;

		var flow = {
			code: ''
		};

		this.flow = flow;

		flow.result = node.build(this, output);

		this.flow = previousFlow;

		return flow;
	}

	public function flowNodeFromShaderStage(shaderStage:String, node:Dynamic, output:String = null, propertyName:String = null):Map<String, Dynamic> {
		var previousShaderStage = this.shaderStage;

		this.setShaderStage(shaderStage);

		var flowData = this.flowChildNode(node, output);

		if (propertyName !== null) {
			flowData.code += `${this.tab + propertyName} = ${flowData.result};\n`;
		}

		this.flowCode[shaderStage] = this.flowCode[shaderStage] + flowData.code;

		this.setShaderStage(previousShaderStage);

		return flowData;
	}

	public function getAttributesArray():Array<Dynamic> {
		return this.attributes.concat(this.bufferAttributes);
	}

	public function getAttributes(/*shaderStage*/):Void {
		console.warn('Abstract function.');
	}

	public function getVaryings(/*shaderStage*/):Void {
		console.warn('Abstract function.');
	}

	public function getVar(type:String, name:String):String {
		return `${this.getType(type)} ${name}`;
	}

	public function getVars(shaderStage:String):String {
		var snippet = '';

		var vars = this.vars[shaderStage];

		if (vars !== undefined) {
			for (variable in vars) {
				snippet += `${this.getVar(variable.type, variable.name)}; `;
			}
		}

		return snippet;
	}

	public function getUniforms(/*shaderStage*/):Void {
		console.warn('Abstract function.');
	}

	public function getCodes(shaderStage:String):String {
		var codes = this.codes[shaderStage];

		var code = '';

		if (codes !== undefined) {
			for (nodeCode in codes) {
				code += nodeCode.code + '\n';
			}
		}

		return code;
	}

	public function getHash():String {
		return this.vertexShader + this.fragmentShader + this.computeShader;
	}

	public function setShaderStage(shaderStage:String):Void {
		this.shaderStage = shaderStage;
	}

	public function getShaderStage():String {
		return this.shaderStage;
	}

	public function setBuildStage(buildStage:String):Void {
		this.buildStage = buildStage;
	}

	public function getBuildStage():String {
		return this.buildStage;
	}

	public function buildCode():Void {
		console.warn('Abstract function.');
	}

	public function build():Dynamic {
		var { object, material } = this;

		if (material !== null) {
			NodeMaterial.fromMaterial(material).build(this);
		} else {
			this.addFlow('compute', object);
		}

		// setup() -> stage 1: create possible new nodes and returns an output reference node
		// analyze()   -> stage 2: analyze nodes to possible optimization and validation
		// generate()  -> stage 3: generate shader

		for (buildStage in defaultBuildStages) {
			this.setBuildStage(buildStage);

			if (this.context.vertex && this.context.vertex.isNode) {
				this.flowNodeFromShaderStage('vertex', this.context.vertex);
			}

			for (shaderStage in shaderStages) {
				this.setShaderStage(shaderStage);

				var flowNodes = this.flowNodes[shaderStage];

				for (node in flowNodes) {
					if (buildStage === 'generate') {
						this.flowNode(node);
					} else {
						node.build(this);
					}
				}
			}
		}

		this.setBuildStage(null);
		this.setShaderStage(null);

		// stage 4: build code for a specific output

		this.buildCode();
		this.buildUpdateNodes();

		return this;
	}

	public function getNodeUniform(uniformNode:Dynamic, type:String):Dynamic {
		if (type === 'float') return new FloatNodeUniform(uniformNode);
		if (type === 'vec2') return new Vector2NodeUniform(uniformNode);
		if (type === 'vec3') return new Vector3NodeUniform(uniformNode);
		if (type === 'vec4') return new Vector4NodeUniform(uniformNode);
		if (type === 'color') return new ColorNodeUniform(uniformNode);
		if (type === 'mat3') return new Matrix3NodeUniform(uniformNode);
		if (type === 'mat4') return new Matrix4NodeUniform(uniformNode);

		throw new Error(`Uniform "${type}" not declared.`);
	}

	public function createNodeMaterial(type:String = 'NodeMaterial'):Dynamic {
		return createNodeMaterialFromType(type);
	}

	public function format(snippet:String, fromType:String, toType:String):String {
		fromType = this.getVectorType(fromType);
		toType = this.getVectorType(toType);

		if (fromType === toType || toType === null || this.isReference(toType)) {
			return snippet;
		}

		var fromTypeLength = this.getTypeLength(fromType);
		var toTypeLength = this.getTypeLength(toType);

		if (fromTypeLength > 4) { // fromType is matrix-like
			// @TODO: ignore for now
			return snippet;
		}

		if (toTypeLength > 4 || toTypeLength === 0) { // toType is matrix-like or unknown
			// @TODO: ignore for now
			return snippet;
		}

		if (fromTypeLength === toTypeLength) {
			return `${this.getType(toType)}( ${snippet} )`;
		}

		if (fromTypeLength > toTypeLength) {
			return this.format(snippet, this.getTypeFromLength(toTypeLength, this.getComponentType(fromType)), toType);
		}

		if (toTypeLength === 4 && fromTypeLength > 1) { // toType is vec4-like
			return `${this.getType(toType)}( ${this.format(snippet, fromType, 'vec3')}, 1.0 )`;
		}

		if (fromTypeLength === 2) { // fromType is vec2-like and toType is vec3-like
			return `${this.getType(toType)}( ${this.format(snippet, fromType, 'vec2')}, 0.0 )`;
		}

		if (fromTypeLength === 1 && toTypeLength > 1 && fromType[0] !== toType[0]) { // fromType is float-like
			// convert a number value to vector type, e.g:
			// vec3( 1u ) -> vec3( float( 1u ) )
			snippet = `${this.getType(this.getComponentType(toType))}( ${snippet} )`;
		}

		return `${this.getType(toType)}( ${snippet} )`; // fromType is float-like
	}

	public function getSignature():String {
		return `// Three.js r${REVISION} - NodeMaterial System\n`;
	}

}

export default NodeBuilder;