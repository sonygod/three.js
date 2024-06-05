import NodeUniform from "./NodeUniform";
import NodeAttribute from "./NodeAttribute";
import NodeVarying from "./NodeVarying";
import NodeVar from "./NodeVar";
import NodeCode from "./NodeCode";
import NodeKeywords from "./NodeKeywords";
import NodeCache from "./NodeCache";
import ParameterNode from "./ParameterNode";
import FunctionNode from "../code/FunctionNode";
import {createNodeMaterialFromType, NodeMaterial} from "../materials/NodeMaterial";
import {NodeUpdateType, defaultBuildStages, shaderStages} from "./constants";

import {
	FloatNodeUniform,
	Vector2NodeUniform,
	Vector3NodeUniform,
	Vector4NodeUniform,
	ColorNodeUniform,
	Matrix3NodeUniform,
	Matrix4NodeUniform,
} from "../../renderers/common/nodes/NodeUniform";

import {REVISION, RenderTarget, Color, Vector2, Vector3, Vector4, IntType, UnsignedIntType, Float16BufferAttribute} from "three";

import {stack} from "./StackNode";
import {getCurrentStack, setCurrentStack} from "../shadernode/ShaderNode";

import CubeRenderTarget from "../../renderers/common/CubeRenderTarget";
import ChainMap from "../../renderers/common/ChainMap";

import PMREMGenerator from "../../renderers/common/extras/PMREMGenerator";

class NodeBuilder {
	public object:Dynamic;
	public material:Dynamic;
	public geometry:Dynamic;
	public renderer:Dynamic;
	public parser:Dynamic;
	public scene:Dynamic;
	public nodes:Array<Dynamic>;
	public updateNodes:Array<Dynamic>;
	public updateBeforeNodes:Array<Dynamic>;
	public hashNodes:Map<String, Dynamic>;
	public lightsNode:Dynamic;
	public environmentNode:Dynamic;
	public fogNode:Dynamic;
	public clippingContext:Dynamic;
	public vertexShader:String;
	public fragmentShader:String;
	public computeShader:String;
	public flowNodes:Map<String, Array<Dynamic>>;
	public flowCode:Map<String, String>;
	public uniforms:Map<String, Array<Dynamic>>;
	public structs:Map<String, Array<Dynamic>>;
	public bindings:Map<String, Array<Dynamic>>;
	public bindingsOffset:Map<String, Int>;
	public bindingsArray:Array<Dynamic>;
	public attributes:Array<Dynamic>;
	public bufferAttributes:Array<Dynamic>;
	public varyings:Array<Dynamic>;
	public codes:Map<String, Array<Dynamic>>;
	public vars:Map<String, Array<Dynamic>>;
	public flow:Dynamic;
	public chaining:Array<Dynamic>;
	public stack:Dynamic;
	public stacks:Array<Dynamic>;
	public tab:String;
	public currentFunctionNode:Dynamic;
	public context:Dynamic;
	public cache:NodeCache;
	public globalCache:NodeCache;
	public flowsData:WeakMap<Dynamic, Dynamic>;
	public shaderStage:String;
	public buildStage:String;

	public constructor(object:Dynamic, renderer:Dynamic, parser:Dynamic, scene:Dynamic = null, material:Dynamic = null) {
		this.object = object;
		this.material = material || (object != null ? object.material : null);
		this.geometry = (object != null ? object.geometry : null);
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
		this.flowNodes = {vertex: [], fragment: [], compute: []};
		this.flowCode = {vertex: "", fragment: "", compute: []};
		this.uniforms = {vertex: [], fragment: [], compute: [], index: 0};
		this.structs = {vertex: [], fragment: [], compute: [], index: 0};
		this.bindings = {vertex: [], fragment: [], compute: []};
		this.bindingsOffset = {vertex: 0, fragment: 0, compute: 0};
		this.bindingsArray = null;
		this.attributes = [];
		this.bufferAttributes = [];
		this.varyings = [];
		this.codes = {};
		this.vars = {};
		this.flow = {code: ""};
		this.chaining = [];
		this.stack = stack();
		this.stacks = [];
		this.tab = "\t";
		this.currentFunctionNode = null;
		this.context = {
			keywords: new NodeKeywords(),
			material: this.material,
		};
		this.cache = new NodeCache();
		this.globalCache = this.cache;
		this.flowsData = new WeakMap();
		this.shaderStage = null;
		this.buildStage = null;
	}

	public createRenderTarget(width:Int, height:Int, options:Dynamic):Dynamic {
		return new RenderTarget(width, height, options);
	}

	public createCubeRenderTarget(size:Int, options:Dynamic):Dynamic {
		return new CubeRenderTarget(size, options);
	}

	public createPMREMGenerator():Dynamic {
		// TODO: Move Materials.js to outside of the Nodes.js in order to remove this function and improve tree-shaking support
		return new PMREMGenerator(this.renderer);
	}

	public includes(node:Dynamic):Bool {
		return this.nodes.indexOf(node) != -1;
	}

	public _getSharedBindings(bindings:Array<Dynamic>):Array<Dynamic> {
		const shared = [];
		for (const binding of bindings) {
			if (binding.shared == true) {
				// nodes is the chainmap key
				const nodes = binding.getNodes();
				let sharedBinding = uniformsGroupCache.get(nodes);
				if (sharedBinding == undefined) {
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

	public getBindings():Array<Dynamic> {
		let bindingsArray = this.bindingsArray;
		if (bindingsArray == null) {
			const bindings = this.bindings;
			this.bindingsArray = bindingsArray = this._getSharedBindings((this.material != null) ? [...bindings.vertex, ...bindings.fragment] : bindings.compute);
		}
		return bindingsArray;
	}

	public setHashNode(node:Dynamic, hash:String) {
		this.hashNodes.set(hash, node);
	}

	public addNode(node:Dynamic) {
		if (this.nodes.indexOf(node) == -1) {
			this.nodes.push(node);
			this.setHashNode(node, node.getHash(this));
		}
	}

	public buildUpdateNodes() {
		for (const node of this.nodes) {
			const updateType = node.getUpdateType();
			const updateBeforeType = node.getUpdateBeforeType();
			if (updateType != NodeUpdateType.NONE) {
				this.updateNodes.push(node.getSelf());
			}
			if (updateBeforeType != NodeUpdateType.NONE) {
				this.updateBeforeNodes.push(node);
			}
		}
	}

	public get currentNode():Dynamic {
		return this.chaining[this.chaining.length - 1];
	}

	public addChain(node:Dynamic) {
		/*
		if ( this.chaining.indexOf( node ) !== - 1 ) {

			console.warn( 'Recursive node: ', node );

		}
		*/
		this.chaining.push(node);
	}

	public removeChain(node:Dynamic) {
		const lastChain = this.chaining.pop();
		if (lastChain != node) {
			throw new Error("NodeBuilder: Invalid node chaining!");
		}
	}

	public getMethod(method:Dynamic):Dynamic {
		return method;
	}

	public getNodeFromHash(hash:String):Dynamic {
		return this.hashNodes.get(hash);
	}

	public addFlow(shaderStage:String, node:Dynamic):Dynamic {
		this.flowNodes[shaderStage].push(node);
		return node;
	}

	public setContext(context:Dynamic) {
		this.context = context;
	}

	public getContext():Dynamic {
		return this.context;
	}

	public setCache(cache:NodeCache) {
		this.cache = cache;
	}

	public getCache():NodeCache {
		return this.cache;
	}

	public isAvailable( /*name*/ ):Bool {
		return false;
	}

	public getVertexIndex():Dynamic {
		console.warn("Abstract function.");
	}

	public getInstanceIndex():Dynamic {
		console.warn("Abstract function.");
	}

	public getFrontFacing():Dynamic {
		console.warn("Abstract function.");
	}

	public getFragCoord():Dynamic {
		console.warn("Abstract function.");
	}

	public isFlipY():Bool {
		return false;
	}

	public generateTexture( /* texture, textureProperty, uvSnippet */ ):Dynamic {
		console.warn("Abstract function.");
	}

	public generateTextureLod( /* texture, textureProperty, uvSnippet, levelSnippet */ ):Dynamic {
		console.warn("Abstract function.");
	}

	public generateConst(type:String, value:Dynamic = null):String {
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
		const typeLength = this.getTypeLength(type);
		const componentType = this.getComponentType(type);
		const generateConst = (value:Dynamic) => this.generateConst(componentType, value);
		if (typeLength == 2) {
			return `${this.getType(type)}( ${generateConst(value.x)}, ${generateConst(value.y)} )`;
		} else if (typeLength == 3) {
			return `${this.getType(type)}( ${generateConst(value.x)}, ${generateConst(value.y)}, ${generateConst(value.z)} )`;
		} else if (typeLength == 4) {
			return `${this.getType(type)}( ${generateConst(value.x)}, ${generateConst(value.y)}, ${generateConst(value.z)}, ${generateConst(value.w)} )`;
		} else if (typeLength > 4 && value != null && (value.isMatrix3 || value.isMatrix4)) {
			return `${this.getType(type)}( ${value.elements.map(generateConst).join(", ")} )`;
		} else if (typeLength > 4) {
			return `${this.getType(type)}()`;
		}
		throw new Error(`NodeBuilder: Type '${type}' not found in generate constant attempt.`);
	}

	public getType(type:String):String {
		if (type == "color") return "vec3";
		return type;
	}

	public generateMethod(method:Dynamic):Dynamic {
		return method;
	}

	public hasGeometryAttribute(name:String):Bool {
		return this.geometry != null && this.geometry.getAttribute(name) != undefined;
	}

	public getAttribute(name:String, type:String):Dynamic {
		const attributes = this.attributes;
		// find attribute
		for (const attribute of attributes) {
			if (attribute.name == name) {
				return attribute;
			}
		}
		// create a new if no exist
		const attribute = new NodeAttribute(name, type);
		attributes.push(attribute);
		return attribute;
	}

	public getPropertyName(node:Dynamic /*, shaderStage*/ ):String {
		return node.name;
	}

	public isVector(type:String):Bool {
		return /vec\d/.test(type);
	}

	public isMatrix(type:String):Bool {
		return /mat\d/.test(type);
	}

	public isReference(type:String):Bool {
		return type == "void" || type == "property" || type == "sampler" || type == "texture" || type == "cubeTexture" || type == "storageTexture";
	}

	public needsColorSpaceToLinear( /*texture*/ ):Bool {
		return false;
	}

	public getComponentTypeFromTexture(texture:Dynamic):String {
		const type = texture.type;
		if (texture.isDataTexture) {
			if (type == IntType) return "int";
			if (type == UnsignedIntType) return "uint";
		}
		return "float";
	}

	public getComponentType(type:String):String {
		type = this.getVectorType(type);
		if (type == "float" || type == "bool" || type == "int" || type == "uint") return type;
		const componentType = /(b|i|u|)(vec|mat)([2-4])/.exec(type);
		if (componentType == null) return null;
		if (componentType[1] == "b") return "bool";
		if (componentType[1] == "i") return "int";
		if (componentType[1] == "u") return "uint";
		return "float";
	}

	public getVectorType(type:String):String {
		if (type == "color") return "vec3";
		if (type == "texture" || type == "cubeTexture" || type == "storageTexture") return "vec4";
		return type;
	}

	public getTypeFromLength(length:Int, componentType:String = "float"):String {
		if (length == 1) return componentType;
		const baseType = typeFromLength.get(length);
		const prefix = componentType == "float" ? "" : componentType[0];
		return prefix + baseType;
	}

	public getTypeFromArray(array:Dynamic):String {
		return typeFromArray.get(array.constructor);
	}

	public getTypeFromAttribute(attribute:Dynamic):String {
		let dataAttribute = attribute;
		if (attribute.isInterleavedBufferAttribute) dataAttribute = attribute.data;
		const array = dataAttribute.array;
		const itemSize = attribute.itemSize;
		const normalized = attribute.normalized;
		let arrayType;
		if (!(attribute instanceof Float16BufferAttribute) && normalized != true) {
			arrayType = this.getTypeFromArray(array);
		}
		return this.getTypeFromLength(itemSize, arrayType);
	}

	public getTypeLength(type:String):Int {
		const vecType = this.getVectorType(type);
		const vecNum = /vec([2-4])/.exec(vecType);
		if (vecNum != null) return Std.parseInt(vecNum[1]);
		if (vecType == "float" || vecType == "bool" || vecType == "int" || vecType == "uint") return 1;
		if (/mat2/.test(type) == true) return 4;
		if (/mat3/.test(type) == true) return 9;
		if (/mat4/.test(type) == true) return 16;
		return 0;
	}

	public getVectorFromMatrix(type:String):String {
		return type.replace("mat", "vec");
	}

	public changeComponentType(type:String, newComponentType:String):String {
		return this.getTypeFromLength(this.getTypeLength(type), newComponentType);
	}

	public getIntegerType(type:String):String {
		const componentType = this.getComponentType(type);
		if (componentType == "int" || componentType == "uint") return type;
		return this.changeComponentType(type, "int");
	}

	public addStack():Dynamic {
		this.stack = stack(this.stack);
		this.stacks.push(getCurrentStack() || this.stack);
		setCurrentStack(this.stack);
		return this.stack;
	}

	public removeStack():Dynamic {
		const lastStack = this.stack;
		this.stack = lastStack.parent;
		setCurrentStack(this.stacks.pop());
		return lastStack;
	}

	public getDataFromNode(node:Dynamic, shaderStage:String = this.shaderStage, cache:Dynamic = null):Dynamic {
		cache = cache == null ? (node.isGlobal(this) ? this.globalCache : this.cache) : cache;
		let nodeData = cache.getNodeData(node);
		if (nodeData == undefined) {
			nodeData = {};
			cache.setNodeData(node, nodeData);
		}
		if (nodeData[shaderStage] == undefined) nodeData[shaderStage] = {};
		return nodeData[shaderStage];
	}

	public getNodeProperties(node:Dynamic, shaderStage:String = "any"):Dynamic {
		const nodeData = this.getDataFromNode(node, shaderStage);
		return nodeData.properties || (nodeData.properties = {outputNode: null});
	}

	public getBufferAttributeFromNode(node:Dynamic, type:String):Dynamic {
		const nodeData = this.getDataFromNode(node);
		let bufferAttribute = nodeData.bufferAttribute;
		if (bufferAttribute == undefined) {
			const index = this.uniforms.index++;
			bufferAttribute = new NodeAttribute("nodeAttribute" + index, type, node);
			this.bufferAttributes.push(bufferAttribute);
			nodeData.bufferAttribute = bufferAttribute;
		}
		return bufferAttribute;
	}

	public getStructTypeFromNode(node:Dynamic, shaderStage:String = this.shaderStage):Dynamic {
		const nodeData = this.getDataFromNode(node, shaderStage);
		if (nodeData.structType == undefined) {
			const index = this.structs.index++;
			node.name = `StructType${index}`;
			this.structs[shaderStage].push(node);
			nodeData.structType = node;
		}
		return node;
	}

	public getUniformFromNode(node:Dynamic, type:String, shaderStage:String = this.shaderStage, name:String = null):Dynamic {
		const nodeData = this.getDataFromNode(node, shaderStage, this.globalCache);
		let nodeUniform = nodeData.uniform;
		if (nodeUniform == undefined) {
			const index = this.uniforms.index++;
			nodeUniform = new NodeUniform(name || ("nodeUniform" + index), type, node);
			this.uniforms[shaderStage].push(nodeUniform);
			nodeData.uniform = nodeUniform;
		}
		return nodeUniform;
	}

	public getVarFromNode(node:Dynamic, name:String = null, type:String = node.getNodeType(this), shaderStage:String = this.shaderStage):Dynamic {
		const nodeData = this.getDataFromNode(node, shaderStage);
		let nodeVar = nodeData.variable;
		if (nodeVar == undefined) {
			const vars = this.vars[shaderStage] || (this.vars[shaderStage] = []);
			if (name == null) name = "nodeVar" + vars.length;
			nodeVar = new NodeVar(name, type);
			vars.push(nodeVar);
			nodeData.variable = nodeVar;
		}
		return nodeVar;
	}

	public getVaryingFromNode(node:Dynamic, name:String = null, type:String = node.getNodeType(this)):Dynamic {
		const nodeData = this.getDataFromNode(node, "any");
		let nodeVarying = nodeData.varying;
		if (nodeVarying == undefined) {
			const varyings = this.varyings;
			const index = varyings.length;
			if (name == null) name = "nodeVarying" + index;
			nodeVarying = new NodeVarying(name, type);
			varyings.push(nodeVarying);
			nodeData.varying = nodeVarying;
		}
		return nodeVarying;
	}

	public getCodeFromNode(node:Dynamic, type:String, shaderStage:String = this.shaderStage):Dynamic {
		const nodeData = this.getDataFromNode(node);
		let nodeCode = nodeData.code;
		if (nodeCode == undefined) {
			const codes = this.codes[shaderStage] || (this.codes[shaderStage] = []);
			const index = codes.length;
			nodeCode = new NodeCode("nodeCode" + index, type);
			codes.push(nodeCode);
			nodeData.code = nodeCode;
		}
		return nodeCode;
	}

	public addLineFlowCode(code:String):NodeBuilder {
		if (code == "") return this;
		code = this.tab + code;
		if (!/;\s*$/.test(code)) {
			code = code + ";\n";
		}
		this.flow.code += code;
		return this;
	}

	public addFlowCode(code:String):NodeBuilder {
		this.flow.code += code;
		return this;
	}

	public addFlowTab():NodeBuilder {
		this.tab += "\t";
		return this;
	}

	public removeFlowTab():NodeBuilder {
		this.tab = this.tab.slice(0, -1);
		return this;
	}

	public getFlowData(node:Dynamic /*, shaderStage*/ ):Dynamic {
		return this.flowsData.get(node);
	}

	public flowNode(node:Dynamic):Dynamic {
		const output = node.getNodeType(this);
		const flowData = this.flowChildNode(node, output);
		this.flowsData.set(node, flowData);
		return flowData;
	}

	public buildFunctionNode(shaderNode:Dynamic):Dynamic {
		const fn = new FunctionNode();
		const previous = this.currentFunctionNode;
		this.currentFunctionNode = fn;
		fn.code = this.buildFunctionCode(shaderNode);
		this.currentFunctionNode = previous;
		return fn;
	}

	public flowShaderNode(shaderNode:Dynamic):Dynamic {
		const layout = shaderNode.layout;
		let inputs;
		if (shaderNode.isArrayInput) {
			inputs = [];
			for (const input of layout.inputs) {
				inputs.push(new ParameterNode(input.type, input.name));
			}
		} else {
			inputs = {};
			for (const input of layout.inputs) {
				inputs[input.name] = new ParameterNode(input.type, input.name);
			}
		}
		//
		shaderNode.layout = null;
		const callNode = shaderNode.call(inputs);
		const flowData = this.flowStagesNode(callNode, layout.type);
		shaderNode.layout = layout;
		return flowData;
	}

	public flowStagesNode(node:Dynamic, output:String = null):Dynamic {
		const previousFlow = this.flow;
		const previousVars = this.vars;
		const previousBuildStage = this.buildStage;
		const flow = {
			code: "",
		};
		this.flow = flow;
		this.vars = {};
		for (const buildStage of defaultBuildStages) {
			this.setBuildStage(buildStage);
			flow.result = node.build(this, output);
		}
		flow.vars = this.getVars(this.shaderStage);
		this.flow = previousFlow;
		this.vars = previousVars;
		this.setBuildStage(previousBuildStage);
		return flow;
	}

	public getFunctionOperator():Dynamic {
		return null;
	}

	public flowChildNode(node:Dynamic, output:String = null):Dynamic {
		const previousFlow = this.flow;
		const flow = {
			code: "",
		};
		this.flow = flow;
		flow.result = node.build(this, output);
		this.flow = previousFlow;
		return flow;
	}

	public flowNodeFromShaderStage(shaderStage:String, node:Dynamic, output:String = null, propertyName:String = null):Dynamic {
		const previousShaderStage = this.shaderStage;
		this.setShaderStage(shaderStage);
		const flowData = this.flowChildNode(node, output);
		if (propertyName != null) {
			flowData.code += `${this.tab + propertyName} = ${flowData.result};\n`;
		}
		this.flowCode[shaderStage] = this.flowCode[shaderStage] + flowData.code;
		this.setShaderStage(previousShaderStage);
		return flowData;
	}

	public getAttributesArray():Array<Dynamic> {
		return this.attributes.concat(this.bufferAttributes);
	}

	public getAttributes( /*shaderStage*/ ):Dynamic {
		console.warn("Abstract function.");
	}

	public getVaryings( /*shaderStage*/ ):Dynamic {
		console.warn("Abstract function.");
	}

	public getVar(type:String, name:String):String {
		return `${this.getType(type)} ${name}`;
	}

	public getVars(shaderStage:String):String {
		let snippet = "";
		const vars = this.vars[shaderStage];
		if (vars != undefined) {
			for (const variable of vars) {
				snippet += `${this.getVar(variable.type, variable.name)}; `;
			}
		}
		return snippet;
	}

	public getUniforms( /*shaderStage*/ ):Dynamic {
		console.warn("Abstract function.");
	}

	public getCodes(shaderStage:String):String {
		const codes = this.codes[shaderStage];
		let code = "";
		if (codes != undefined) {
			for (const nodeCode of codes) {
				code += nodeCode.code + "\n";
			}
		}
		return code;
	}

	public getHash():String {
		return this.vertexShader + this.fragmentShader + this.computeShader;
	}

	public setShaderStage(shaderStage:String) {
		this.shaderStage = shaderStage;
	}

	public getShaderStage():String {
		return this.shaderStage;
	}

	public setBuildStage(buildStage:String) {
		this.buildStage = buildStage;
	}

	public getBuildStage():String {
		return this.buildStage;
	}

	public buildCode():Dynamic {
		console.warn("Abstract function.");
	}

	public build():NodeBuilder {
		const {object, material} = this;
		if (material != null) {
			NodeMaterial.fromMaterial(material).build(this);
		} else {
			this.addFlow("compute", object);
		}
		// setup() -> stage 1: create possible new nodes and returns an output reference node
		// analyze()   -> stage 2: analyze nodes to possible optimization and validation
		// generate()  -> stage 3: generate shader
		for (const buildStage of defaultBuildStages) {
			this.setBuildStage(buildStage);
			if (this.context.vertex && this.context.vertex.isNode) {
				this.flowNodeFromShaderStage("vertex", this.context.vertex);
			}
			for (const shaderStage of shaderStages) {
				this.setShaderStage(shaderStage);
				const flowNodes = this.flowNodes[shaderStage];
				for (const node of flowNodes) {
					if (buildStage == "generate") {
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

	public getNodeUniform(uniformNode:Dynamic, type:String):Dynamic {
		if (type == "float") return new FloatNodeUniform(uniformNode);
		if (type == "vec2") return new Vector2NodeUniform(uniformNode);
		if (type == "vec3") return new Vector3NodeUniform(uniformNode);
		if (type == "vec4") return new Vector4NodeUniform(uniformNode);
		if (type == "color") return new ColorNodeUniform(uniformNode);
		if (type == "mat3") return new Matrix3NodeUniform(uniformNode);
		if (type == "mat4") return new Matrix4NodeUniform(uniformNode);
		throw new Error(`Uniform "${type}" not declared.`);
	}

	public createNodeMaterial(type:String = "NodeMaterial"):Dynamic {
		// TODO: Move Materials.js to outside of the Nodes.js in order to remove this function and improve tree-shaking support
		return createNodeMaterialFromType(type);
	}

	public format(snippet:String, fromType:String, toType:String):String {
		fromType = this.getVectorType(fromType);
		toType = this.getVectorType(toType);
		if (fromType == toType || toType == null || this.isReference(toType)) {
			return snippet;
		}
		const fromTypeLength = this.getTypeLength(fromType);
		const toTypeLength = this.getTypeLength(toType);
		if (fromTypeLength > 4) { // fromType is matrix-like
			// @TODO: ignore for now
			return snippet;
		}
		if (toTypeLength > 4 || toTypeLength == 0) { // toType is matrix-like or unknown
			// @TODO: ignore for now
			return snippet;
		}
		if (fromTypeLength == toTypeLength) {
			return `${this.getType(toType)}( ${snippet} )`;
		}
		if (fromTypeLength > toTypeLength) {
			return this.format(`${snippet}.${'xyz'.slice(0, toTypeLength)}`, this.getTypeFromLength(toTypeLength, this.getComponentType(fromType)), toType);
		}
		if (toTypeLength == 4 && fromTypeLength > 1) { // toType is vec4-like
			return `${this.getType(toType)}( ${this.format(snippet, fromType, "vec3")}, 1.0 )`;
		}
		if (fromTypeLength == 2) { // fromType is vec2-like and toType is vec3-like
			return `${this.getType(toType)}( ${this.format(snippet, fromType, "vec2")}, 0.0 )`;
		}
		if (fromTypeLength == 1 && toTypeLength > 1 && fromType[0] != toType[0]) { // fromType is float-like
			// convert a number value to vector type, e.g:
			// vec3( 1u ) -> vec3( float( 1u ) )
			snippet = `${this.getType(this.getComponentType(toType))}( ${snippet} )`;
		}
		return `${this.getType(toType)}( ${snippet} )`; // fromType is float-like
	}

	public getSignature():String {
		return `// Three.js r${REVISION} - NodeMaterial System\n`;
	}
}

const uniformsGroupCache = new ChainMap();
const typeFromLength = new Map([
	[2, "vec2"],
	[3, "vec3"],
	[4, "vec4"],
	[9, "mat3"],
	[16, "mat4"],
]);
const typeFromArray = new Map([
	[Int8Array, "int"],
	[Int16Array, "int"],
	[Int32Array, "int"],
	[Uint8Array, "uint"],
	[Uint16Array, "uint"],
	[Uint32Array, "uint"],
	[Float32Array, "float"],
]);

const toFloat = (value:Dynamic) => {
	value = Std.parseFloat(value);
	return value + (value % 1 ? "" : ".0");
};

export default NodeBuilder;