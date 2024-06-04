import NodeUniform from "./NodeUniform";
import NodeAttribute from "./NodeAttribute";
import NodeVarying from "./NodeVarying";
import NodeVar from "./NodeVar";
import NodeCode from "./NodeCode";
import NodeKeywords from "./NodeKeywords";
import NodeCache from "./NodeCache";
import ParameterNode from "./ParameterNode";
import FunctionNode from "../code/FunctionNode";
import { createNodeMaterialFromType, NodeMaterial } from "../materials/NodeMaterial";
import { NodeUpdateType, defaultBuildStages, shaderStages } from "./constants";

import {
	FloatNodeUniform, Vector2NodeUniform, Vector3NodeUniform, Vector4NodeUniform,
	ColorNodeUniform, Matrix3NodeUniform, Matrix4NodeUniform
} from "../../renderers/common/nodes/NodeUniform";

import { REVISION, RenderTarget, Color, Vector2, Vector3, Vector4, IntType, UnsignedIntType, Float16BufferAttribute } from "three";

import { stack } from "./StackNode";
import { getCurrentStack, setCurrentStack } from "../shadernode/ShaderNode";

import CubeRenderTarget from "../../renderers/common/CubeRenderTarget";
import ChainMap from "../../renderers/common/ChainMap";

import PMREMGenerator from "../../renderers/common/extras/PMREMGenerator";

class NodeBuilder {
	object:Dynamic;
	material:Dynamic;
	geometry:Dynamic;
	renderer:Dynamic;
	parser:Dynamic;
	scene:Dynamic;
	nodes:Array<Dynamic>;
	updateNodes:Array<Dynamic>;
	updateBeforeNodes:Array<Dynamic>;
	hashNodes:Map<String, Dynamic>;
	lightsNode:Dynamic;
	environmentNode:Dynamic;
	fogNode:Dynamic;
	clippingContext:Dynamic;
	vertexShader:String;
	fragmentShader:String;
	computeShader:String;
	flowNodes:Map<String, Array<Dynamic>>;
	flowCode:Map<String, String>;
	uniforms:Map<String, Array<Dynamic>>;
	structs:Map<String, Array<Dynamic>>;
	bindings:Map<String, Array<Dynamic>>;
	bindingsOffset:Map<String, Int>;
	bindingsArray:Array<Dynamic>;
	attributes:Array<Dynamic>;
	bufferAttributes:Array<Dynamic>;
	varyings:Array<Dynamic>;
	codes:Map<String, Array<Dynamic>>;
	vars:Map<String, Array<Dynamic>>;
	flow:Map<String, String>;
	chaining:Array<Dynamic>;
	stack:Dynamic;
	stacks:Array<Dynamic>;
	tab:String;
	currentFunctionNode:Dynamic;
	context:Dynamic;
	cache:NodeCache;
	globalCache:NodeCache;
	flowsData:WeakMap<Dynamic, Dynamic>;
	shaderStage:String;
	buildStage:String;
	uniformsGroupCache:ChainMap;
	typeFromLength:Map<Int, String>;
	typeFromArray:Map<Dynamic, String>;

	constructor(object:Dynamic, renderer:Dynamic, parser:Dynamic, scene:Dynamic = null, material:Dynamic = null) {
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
		this.flowNodes = new Map();
		this.flowCode = new Map();
		this.uniforms = new Map();
		this.structs = new Map();
		this.bindings = new Map();
		this.bindingsOffset = new Map();
		this.bindingsArray = null;
		this.attributes = [];
		this.bufferAttributes = [];
		this.varyings = [];
		this.codes = new Map();
		this.vars = new Map();
		this.flow = new Map();
		this.chaining = [];
		this.stack = stack();
		this.stacks = [];
		this.tab = "\t";
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
		this.uniformsGroupCache = new ChainMap();
		this.typeFromLength = new Map([
			[2, "vec2"],
			[3, "vec3"],
			[4, "vec4"],
			[9, "mat3"],
			[16, "mat4"]
		]);
		this.typeFromArray = new Map([
			[Int8Array, "int"],
			[Int16Array, "int"],
			[Int32Array, "int"],
			[Uint8Array, "uint"],
			[Uint16Array, "uint"],
			[Uint32Array, "uint"],
			[Float32Array, "float"]
		]);
	}

	createRenderTarget(width:Int, height:Int, options:Dynamic):Dynamic {
		return new RenderTarget(width, height, options);
	}

	createCubeRenderTarget(size:Int, options:Dynamic):Dynamic {
		return new CubeRenderTarget(size, options);
	}

	createPMREMGenerator():Dynamic {
		return new PMREMGenerator(this.renderer);
	}

	includes(node:Dynamic):Bool {
		return this.nodes.indexOf(node) != -1;
	}

	_getSharedBindings(bindings:Array<Dynamic>):Array<Dynamic> {
		var shared = [];
		for (var binding in bindings) {
			if (binding.shared == true) {
				var nodes = binding.getNodes();
				var sharedBinding = this.uniformsGroupCache.get(nodes);
				if (sharedBinding == undefined) {
					this.uniformsGroupCache.set(nodes, binding);
					sharedBinding = binding;
				}
				shared.push(sharedBinding);
			} else {
				shared.push(binding);
			}
		}
		return shared;
	}

	getBindings():Array<Dynamic> {
		var bindingsArray = this.bindingsArray;
		if (bindingsArray == null) {
			var bindings = this.bindings;
			this.bindingsArray = bindingsArray = this._getSharedBindings((this.material != null) ? [
				...bindings.vertex,
				...bindings.fragment
			] : bindings.compute);
		}
		return bindingsArray;
	}

	setHashNode(node:Dynamic, hash:String):Void {
		this.hashNodes.set(hash, node);
	}

	addNode(node:Dynamic):Void {
		if (this.nodes.indexOf(node) == -1) {
			this.nodes.push(node);
			this.setHashNode(node, node.getHash(this));
		}
	}

	buildUpdateNodes():Void {
		for (var node in this.nodes) {
			var updateType = node.getUpdateType();
			var updateBeforeType = node.getUpdateBeforeType();
			if (updateType != NodeUpdateType.NONE) {
				this.updateNodes.push(node.getSelf());
			}
			if (updateBeforeType != NodeUpdateType.NONE) {
				this.updateBeforeNodes.push(node);
			}
		}
	}

	get currentNode():Dynamic {
		return this.chaining[this.chaining.length - 1];
	}

	addChain(node:Dynamic):Void {
		this.chaining.push(node);
	}

	removeChain(node:Dynamic):Void {
		var lastChain = this.chaining.pop();
		if (lastChain != node) {
			throw new Error("NodeBuilder: Invalid node chaining!");
		}
	}

	getMethod(method:Dynamic):Dynamic {
		return method;
	}

	getNodeFromHash(hash:String):Dynamic {
		return this.hashNodes.get(hash);
	}

	addFlow(shaderStage:String, node:Dynamic):Dynamic {
		var flowNodes = this.flowNodes.get(shaderStage) || [];
		flowNodes.push(node);
		this.flowNodes.set(shaderStage, flowNodes);
		return node;
	}

	setContext(context:Dynamic):Void {
		this.context = context;
	}

	getContext():Dynamic {
		return this.context;
	}

	setCache(cache:NodeCache):Void {
		this.cache = cache;
	}

	getCache():NodeCache {
		return this.cache;
	}

	isAvailable(name:String):Bool {
		return false;
	}

	getVertexIndex():Dynamic {
		console.warn("Abstract function.");
	}

	getInstanceIndex():Dynamic {
		console.warn("Abstract function.");
	}

	getFrontFacing():Dynamic {
		console.warn("Abstract function.");
	}

	getFragCoord():Dynamic {
		console.warn("Abstract function.");
	}

	isFlipY():Bool {
		return false;
	}

	generateTexture(texture:Dynamic, textureProperty:String, uvSnippet:String):Dynamic {
		console.warn("Abstract function.");
	}

	generateTextureLod(texture:Dynamic, textureProperty:String, uvSnippet:String, levelSnippet:String):Dynamic {
		console.warn("Abstract function.");
	}

	generateConst(type:String, value:Dynamic = null):String {
		if (value == null) {
			if (type == "float" || type == "int" || type == "uint") value = 0;
			else if (type == "bool") value = false;
			else if (type == "color") value = new Color();
			else if (type == "vec2") value = new Vector2();
			else if (type == "vec3") value = new Vector3();
			else if (type == "vec4") value = new Vector4();
		}
		if (type == "float") return toFloat(value);
		if (type == "int") return `${Math.round(value)}`;
		if (type == "uint") return value >= 0 ? `${Math.round(value)}u` : "0u";
		if (type == "bool") return value ? "true" : "false";
		if (type == "color") return `${this.getType("vec3")}( ${toFloat(value.r)}, ${toFloat(value.g)}, ${toFloat(value.b)} )`;
		var typeLength = this.getTypeLength(type);
		var componentType = this.getComponentType(type);
		var generateConst = (value) => this.generateConst(componentType, value);
		if (typeLength == 2) {
			return `${this.getType(type)}( ${generateConst(value.x)}, ${generateConst(value.y)} )`;
		} else if (typeLength == 3) {
			return `${this.getType(type)}( ${generateConst(value.x)}, ${generateConst(value.y)}, ${generateConst(value.z)} )`;
		} else if (typeLength == 4) {
			return `${this.getType(type)}( ${generateConst(value.x)}, ${generateConst(value.y)}, ${generateConst(value.z)}, ${generateConst(value.w)} )`;
		} else if (typeLength > 4 && value && (value.isMatrix3 || value.isMatrix4)) {
			return `${this.getType(type)}( ${value.elements.map(generateConst).join(", ")} )`;
		} else if (typeLength > 4) {
			return `${this.getType(type)}()`;
		}
		throw new Error(`NodeBuilder: Type '${type}' not found in generate constant attempt.`);
	}

	getType(type:String):String {
		if (type == "color") return "vec3";
		return type;
	}

	generateMethod(method:Dynamic):Dynamic {
		return method;
	}

	hasGeometryAttribute(name:String):Bool {
		return this.geometry && this.geometry.getAttribute(name) != undefined;
	}

	getAttribute(name:String, type:String):Dynamic {
		var attributes = this.attributes;
		for (var attribute in attributes) {
			if (attribute.name == name) {
				return attribute;
			}
		}
		var attribute = new NodeAttribute(name, type);
		attributes.push(attribute);
		return attribute;
	}

	getPropertyName(node:Dynamic, shaderStage:String):String {
		return node.name;
	}

	isVector(type:String):Bool {
		return /vec\d/.test(type);
	}

	isMatrix(type:String):Bool {
		return /mat\d/.test(type);
	}

	isReference(type:String):Bool {
		return type == "void" || type == "property" || type == "sampler" || type == "texture" || type == "cubeTexture" || type == "storageTexture";
	}

	needsColorSpaceToLinear(texture:Dynamic):Bool {
		return false;
	}

	getComponentTypeFromTexture(texture:Dynamic):String {
		var type = texture.type;
		if (texture.isDataTexture) {
			if (type == IntType) return "int";
			if (type == UnsignedIntType) return "uint";
		}
		return "float";
	}

	getComponentType(type:String):String {
		type = this.getVectorType(type);
		if (type == "float" || type == "bool" || type == "int" || type == "uint") return type;
		var componentType = /(b|i|u|)(vec|mat)([2-4])/.exec(type);
		if (componentType == null) return null;
		if (componentType[1] == "b") return "bool";
		if (componentType[1] == "i") return "int";
		if (componentType[1] == "u") return "uint";
		return "float";
	}

	getVectorType(type:String):String {
		if (type == "color") return "vec3";
		if (type == "texture" || type == "cubeTexture" || type == "storageTexture") return "vec4";
		return type;
	}

	getTypeFromLength(length:Int, componentType:String = "float"):String {
		if (length == 1) return componentType;
		var baseType = this.typeFromLength.get(length);
		var prefix = componentType == "float" ? "" : componentType[0];
		return prefix + baseType;
	}

	getTypeFromArray(array:Dynamic):String {
		return this.typeFromArray.get(array.constructor);
	}

	getTypeFromAttribute(attribute:Dynamic):String {
		var dataAttribute = attribute;
		if (attribute.isInterleavedBufferAttribute) dataAttribute = attribute.data;
		var array = dataAttribute.array;
		var itemSize = attribute.itemSize;
		var normalized = attribute.normalized;
		var arrayType;
		if (!(attribute instanceof Float16BufferAttribute) && normalized != true) {
			arrayType = this.getTypeFromArray(array);
		}
		return this.getTypeFromLength(itemSize, arrayType);
	}

	getTypeLength(type:String):Int {
		var vecType = this.getVectorType(type);
		var vecNum = /vec([2-4])/.exec(vecType);
		if (vecNum != null) return Std.parseInt(vecNum[1]);
		if (vecType == "float" || vecType == "bool" || vecType == "int" || vecType == "uint") return 1;
		if (/mat2/.test(type) == true) return 4;
		if (/mat3/.test(type) == true) return 9;
		if (/mat4/.test(type) == true) return 16;
		return 0;
	}

	getVectorFromMatrix(type:String):String {
		return type.replace("mat", "vec");
	}

	changeComponentType(type:String, newComponentType:String):String {
		return this.getTypeFromLength(this.getTypeLength(type), newComponentType);
	}

	getIntegerType(type:String):String {
		var componentType = this.getComponentType(type);
		if (componentType == "int" || componentType == "uint") return type;
		return this.changeComponentType(type, "int");
	}

	addStack():Dynamic {
		this.stack = stack(this.stack);
		this.stacks.push(getCurrentStack() || this.stack);
		setCurrentStack(this.stack);
		return this.stack;
	}

	removeStack():Dynamic {
		var lastStack = this.stack;
		this.stack = lastStack.parent;
		setCurrentStack(this.stacks.pop());
		return lastStack;
	}

	getDataFromNode(node:Dynamic, shaderStage:String = this.shaderStage, cache:Dynamic = null):Dynamic {
		cache = cache == null ? (node.isGlobal(this) ? this.globalCache : this.cache) : cache;
		var nodeData = cache.getNodeData(node);
		if (nodeData == undefined) {
			nodeData = {};
			cache.setNodeData(node, nodeData);
		}
		if (nodeData[shaderStage] == undefined) nodeData[shaderStage] = {};
		return nodeData[shaderStage];
	}

	getNodeProperties(node:Dynamic, shaderStage:String = "any"):Dynamic {
		var nodeData = this.getDataFromNode(node, shaderStage);
		return nodeData.properties || (nodeData.properties = {outputNode: null});
	}

	getBufferAttributeFromNode(node:Dynamic, type:String):Dynamic {
		var nodeData = this.getDataFromNode(node);
		var bufferAttribute = nodeData.bufferAttribute;
		if (bufferAttribute == undefined) {
			var index = this.uniforms.index++;
			bufferAttribute = new NodeAttribute("nodeAttribute" + index, type, node);
			this.bufferAttributes.push(bufferAttribute);
			nodeData.bufferAttribute = bufferAttribute;
		}
		return bufferAttribute;
	}

	getStructTypeFromNode(node:Dynamic, shaderStage:String = this.shaderStage):Dynamic {
		var nodeData = this.getDataFromNode(node, shaderStage);
		if (nodeData.structType == undefined) {
			var index = this.structs.index++;
			node.name = `StructType${index}`;
			var structs = this.structs.get(shaderStage) || [];
			structs.push(node);
			this.structs.set(shaderStage, structs);
			nodeData.structType = node;
		}
		return node;
	}

	getUniformFromNode(node:Dynamic, type:String, shaderStage:String = this.shaderStage, name:String = null):Dynamic {
		var nodeData = this.getDataFromNode(node, shaderStage, this.globalCache);
		var nodeUniform = nodeData.uniform;
		if (nodeUniform == undefined) {
			var index = this.uniforms.index++;
			nodeUniform = new NodeUniform(name || ("nodeUniform" + index), type, node);
			var uniforms = this.uniforms.get(shaderStage) || [];
			uniforms.push(nodeUniform);
			this.uniforms.set(shaderStage, uniforms);
			nodeData.uniform = nodeUniform;
		}
		return nodeUniform;
	}

	getVarFromNode(node:Dynamic, name:String = null, type:String = node.getNodeType(this), shaderStage:String = this.shaderStage):Dynamic {
		var nodeData = this.getDataFromNode(node, shaderStage);
		var nodeVar = nodeData.variable;
		if (nodeVar == undefined) {
			var vars = this.vars.get(shaderStage) || [];
			if (name == null) name = "nodeVar" + vars.length;
			nodeVar = new NodeVar(name, type);
			vars.push(nodeVar);
			this.vars.set(shaderStage, vars);
			nodeData.variable = nodeVar;
		}
		return nodeVar;
	}

	getVaryingFromNode(node:Dynamic, name:String = null, type:String = node.getNodeType(this)):Dynamic {
		var nodeData = this.getDataFromNode(node, "any");
		var nodeVarying = nodeData.varying;
		if (nodeVarying == undefined) {
			var varyings = this.varyings;
			var index = varyings.length;
			if (name == null) name = "nodeVarying" + index;
			nodeVarying = new NodeVarying(name, type);
			varyings.push(nodeVarying);
			nodeData.varying = nodeVarying;
		}
		return nodeVarying;
	}

	getCodeFromNode(node:Dynamic, type:String, shaderStage:String = this.shaderStage):Dynamic {
		var nodeData = this.getDataFromNode(node);
		var nodeCode = nodeData.code;
		if (nodeCode == undefined) {
			var codes = this.codes.get(shaderStage) || [];
			var index = codes.length;
			nodeCode = new NodeCode("nodeCode" + index, type);
			codes.push(nodeCode);
			nodeData.code = nodeCode;
		}
		return nodeCode;
	}

	addLineFlowCode(code:String):NodeBuilder {
		if (code == "") return this;
		code = this.tab + code;
		if (!/;\s*$/.test(code)) {
			code = code + ";\n";
		}
		this.flow.code += code;
		return this;
	}

	addFlowCode(code:String):NodeBuilder {
		this.flow.code += code;
		return this;
	}

	addFlowTab():NodeBuilder {
		this.tab += "\t";
		return this;
	}

	removeFlowTab():NodeBuilder {
		this.tab = this.tab.slice(0, -1);
		return this;
	}

	getFlowData(node:Dynamic, shaderStage:String):Dynamic {
		return this.flowsData.get(node);
	}

	flowNode(node:Dynamic):Dynamic {
		var output = node.getNodeType(this);
		var flowData = this.flowChildNode(node, output);
		this.flowsData.set(node, flowData);
		return flowData;
	}

	buildFunctionNode(shaderNode:Dynamic):Dynamic {
		var fn = new FunctionNode();
		var previous = this.currentFunctionNode;
		this.currentFunctionNode = fn;
		fn.code = this.buildFunctionCode(shaderNode);
		this.currentFunctionNode = previous;
		return fn;
	}

	flowShaderNode(shaderNode:Dynamic):Dynamic {
		var layout = shaderNode.layout;
		var inputs;
		if (shaderNode.isArrayInput) {
			inputs = [];
			for (var input in layout.inputs) {
				inputs.push(new ParameterNode(input.type, input.name));
			}
		} else {
			inputs = {};
			for (var input in layout.inputs) {
				inputs[input.name] = new ParameterNode(input.type, input.name);
			}
		}
		shaderNode.layout = null;
		var callNode = shaderNode.call(inputs);
		var flowData = this.flowStagesNode(callNode, layout.type);
		shaderNode.layout = layout;
		return flowData;
	}

	flowStagesNode(node:Dynamic, output:String = null):Dynamic {
		var previousFlow = this.flow;
		var previousVars = this.vars;
		var previousBuildStage = this.buildStage;
		var flow = {
			code: ""
		};
		this.flow = flow;
		this.vars = new Map();
		for (var buildStage in defaultBuildStages) {
			this.setBuildStage(buildStage);
			flow.result = node.build(this, output);
		}
		flow.vars = this.getVars(this.shaderStage);
		this.flow = previousFlow;
		this.vars = previousVars;
		this.setBuildStage(previousBuildStage);
		return flow;
	}

	getFunctionOperator():Dynamic {
		return null;
	}

	flowChildNode(node:Dynamic, output:String = null):Dynamic {
		var previousFlow = this.flow;
		var flow = {
			code: ""
		};
		this.flow = flow;
		flow.result = node.build(this, output);
		this.flow = previousFlow;
		return flow;
	}

	flowNodeFromShaderStage(shaderStage:String, node:Dynamic, output:String = null, propertyName:String = null):Dynamic {
		var previousShaderStage = this.shaderStage;
		this.setShaderStage(shaderStage);
		var flowData = this.flowChildNode(node, output);
		if (propertyName != null) {
			flowData.code += `${this.tab + propertyName} = ${flowData.result};\n`;
		}
		var flowCode = this.flowCode.get(shaderStage) || "";
		this.flowCode.set(shaderStage, flowCode + flowData.code);
		this.setShaderStage(previousShaderStage);
		return flowData;
	}

	getAttributesArray():Array<Dynamic> {
		return this.attributes.concat(this.bufferAttributes);
	}

	getAttributes(shaderStage:String):Dynamic {
		console.warn("Abstract function.");
	}

	getVaryings(shaderStage:String):Dynamic {
		console.warn("Abstract function.");
	}

	getVar(type:String, name:String):String {
		return `${this.getType(type)} ${name}`;
	}

	getVars(shaderStage:String):String {
		var snippet = "";
		var vars = this.vars.get(shaderStage);
		if (vars != undefined) {
			for (var variable in vars) {
				snippet += `${this.getVar(variable.type, variable.name)}; `;
			}
		}
		return snippet;
	}

	getUniforms(shaderStage:String):Dynamic {
		console.warn("Abstract function.");
	}

	getCodes(shaderStage:String):String {
		var codes = this.codes.get(shaderStage);
		var code = "";
		if (codes != undefined) {
			for (var nodeCode in codes) {
				code += nodeCode.code + "\n";
			}
		}
		return code;
	}

	getHash():String {
		return this.vertexShader + this.fragmentShader + this.computeShader;
	}

	setShaderStage(shaderStage:String):Void {
		this.shaderStage = shaderStage;
	}

	getShaderStage():String {
		return this.shaderStage;
	}

	setBuildStage(buildStage:String):Void {
		this.buildStage = buildStage;
	}

	getBuildStage():String {
		return this.buildStage;
	}

	buildCode():Void {
		console.warn("Abstract function.");
	}

	build():NodeBuilder {
		var object = this.object;
		var material = this.material;
		if (material != null) {
			NodeMaterial.fromMaterial(material).build(this);
		} else {
			this.addFlow("compute", object);
		}
		for (var buildStage in defaultBuildStages) {
			this.setBuildStage(buildStage);
			if (this.context.vertex && this.context.vertex.isNode) {
				this.flowNodeFromShaderStage("vertex", this.context.vertex);
			}
			for (var shaderStage in shaderStages) {
				this.setShaderStage(shaderStage);
				var flowNodes = this.flowNodes.get(shaderStage);
				if (flowNodes != null) {
					for (var node in flowNodes) {
						if (buildStage == "generate") {
							this.flowNode(node);
						} else {
							node.build(this);
						}
					}
				}
			}
		}
		this.setBuildStage(null);
		this.setShaderStage(null);
		this.buildCode();
		this.buildUpdateNodes();
		return this;
	}

	getNodeUniform(uniformNode:Dynamic, type:String):Dynamic {
		if (type == "float") return new FloatNodeUniform(uniformNode);
		if (type == "vec2") return new Vector2NodeUniform(uniformNode);
		if (type == "vec3") return new Vector3NodeUniform(uniformNode);
		if (type == "vec4") return new Vector4NodeUniform(uniformNode);
		if (type == "color") return new ColorNodeUniform(uniformNode);
		if (type == "mat3") return new Matrix3NodeUniform(uniformNode);
		if (type == "mat4") return new Matrix4NodeUniform(uniformNode);
		throw new Error(`Uniform "${type}" not declared.`);
	}

	createNodeMaterial(type:String = "NodeMaterial"):Dynamic {
		return createNodeMaterialFromType(type);
	}

	format(snippet:String, fromType:String, toType:String):String {
		fromType = this.getVectorType(fromType);
		toType = this.getVectorType(toType);
		if (fromType == toType || toType == null || this.isReference(toType)) {
			return snippet;
		}
		var fromTypeLength = this.getTypeLength(fromType);
		var toTypeLength = this.getTypeLength(toType);
		if (fromTypeLength > 4) {
			return snippet;
		}
		if (toTypeLength > 4 || toTypeLength == 0) {
			return snippet;
		}
		if (fromTypeLength == toTypeLength) {
			return `${this.getType(toType)}( ${snippet} )`;
		}
		if (fromTypeLength > toTypeLength) {
			return this.format(`${snippet}.${"xyz".slice(0, toTypeLength)}`, this.getTypeFromLength(toTypeLength, this.getComponentType(fromType)), toType);
		}
		if (toTypeLength == 4 && fromTypeLength > 1) {
			return `${this.getType(toType)}( ${this.format(snippet, fromType, "vec3")}, 1.0 )`;
		}
		if (fromTypeLength == 2) {
			return `${this.getType(toType)}( ${this.format(snippet, fromType, "vec2")}, 0.0 )`;
		}
		if (fromTypeLength == 1 && toTypeLength > 1 && fromType[0] != toType[0]) {
			snippet = `${this.getType(this.getComponentType(toType))}( ${snippet} )`;
		}
		return `${this.getType(toType)}( ${snippet} )`;
	}

	getSignature():String {
		return `// Three.js r${REVISION} - NodeMaterial System\n`;
	}
}

var toFloat = (value:Dynamic) => {
	value = Std.parseFloat(value);
	return value + (value % 1 ? "" : ".0");
};

export default NodeBuilder;