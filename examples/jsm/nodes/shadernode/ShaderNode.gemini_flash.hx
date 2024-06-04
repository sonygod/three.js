import Node from "../core/Node";
import ArrayElementNode from "../utils/ArrayElementNode";
import ConvertNode from "../utils/ConvertNode";
import JoinNode from "../utils/JoinNode";
import SplitNode from "../utils/SplitNode";
import SetNode from "../utils/SetNode";
import ConstNode from "../core/ConstNode";
import {getValueFromType, getValueType} from "../core/NodeUtils";

//

class ShaderNodeObject {
	public var obj:Dynamic;
	public var altType:Null<String>;

	public function new(obj:Dynamic, altType:Null<String> = null) {
		this.obj = obj;
		this.altType = altType;
	}

	public function toNode():Dynamic {
		if (getValueType(obj) == "node") {
			return obj;
		} else if ((altType == null && (getValueType(obj) == "float" || getValueType(obj) == "boolean")) || (getValueType(obj) != null && getValueType(obj) != "shader" && getValueType(obj) != "string")) {
			return nodeObject(getConstNode(obj, altType));
		} else if (getValueType(obj) == "shader") {
			return tslFn(obj);
		}
		return obj;
	}
}

class ShaderNodeObjects {
	public var objects:Dynamic;
	public var altType:Null<String>;

	public function new(objects:Dynamic, altType:Null<String> = null) {
		this.objects = objects;
		this.altType = altType;
	}

	public function toNode():Dynamic {
		for (name in objects) {
			objects[name] = nodeObject(objects[name], altType);
		}
		return objects;
	}
}

class ShaderNodeArray {
	public var array:Array<Dynamic>;
	public var altType:Null<String>;

	public function new(array:Array<Dynamic>, altType:Null<String> = null) {
		this.array = array;
		this.altType = altType;
	}

	public function toNode():Array<Dynamic> {
		for (i in 0...array.length) {
			array[i] = nodeObject(array[i], altType);
		}
		return array;
	}
}

class ShaderNodeProxy {
	public var NodeClass:Dynamic;
	public var scope:Dynamic;
	public var factor:Dynamic;
	public var settings:Dynamic;

	public function new(NodeClass:Dynamic, scope:Dynamic = null, factor:Dynamic = null, settings:Dynamic = null) {
		this.NodeClass = NodeClass;
		this.scope = scope;
		this.factor = factor;
		this.settings = settings;
	}

	public function toNode(params:Array<Dynamic>):Dynamic {
		if (scope == null) {
			return assignNode(new NodeClass(nodeArray(params)));
		} else if (factor != null) {
			return assignNode(new NodeClass(scope, nodeArray(params), factor));
		} else {
			return assignNode(new NodeClass(scope, nodeArray(params)));
		}
	}

	inline function assignNode(node:Dynamic):Dynamic {
		return nodeObject(settings != null ? Object.assign(node, settings) : node);
	}
}

class ShaderNodeImmutable {
	public var NodeClass:Dynamic;
	public var params:Array<Dynamic>;

	public function new(NodeClass:Dynamic, params:Array<Dynamic>) {
		this.NodeClass = NodeClass;
		this.params = params;
	}

	public function toNode():Dynamic {
		return nodeObject(new NodeClass(nodeArray(params)));
	}
}

class ShaderCallNodeInternal extends Node {
	public var shaderNode:Dynamic;
	public var inputNodes:Array<Dynamic>;

	public function new(shaderNode:Dynamic, inputNodes:Array<Dynamic>) {
		super();
		this.shaderNode = shaderNode;
		this.inputNodes = inputNodes;
	}

	override public function getNodeType(builder:Dynamic):String {
		var properties = builder.getNodeProperties(this);
		if (properties.outputNode == null) {
			properties.outputNode = setupOutput(builder);
		}
		return properties.outputNode.getNodeType(builder);
	}

	override public function call(builder:Dynamic):Dynamic {
		var jsFunc = shaderNode.jsFunc;
		var outputNode = inputNodes != null ? jsFunc(inputNodes, builder.stack, builder) : jsFunc(builder.stack, builder);
		return nodeObject(outputNode);
	}

	override public function setup(builder:Dynamic):Dynamic {
		var properties = builder.getNodeProperties(this);
		return properties.outputNode || setupOutput(builder);
	}

	override public function setupOutput(builder:Dynamic):Dynamic {
		builder.addStack();
		builder.stack.outputNode = call(builder);
		return builder.removeStack();
	}

	override public function generate(builder:Dynamic, output:Dynamic):Dynamic {
		var properties = builder.getNodeProperties(this);
		if (properties.outputNode == null) {
			// TSL: It's recommended to use `tslFn` in setup() pass.
			return call(builder).build(builder, output);
		}
		return super.generate(builder, output);
	}
}

class ShaderNodeInternal extends Node {
	public var jsFunc:Dynamic;
	public var layout:Dynamic;

	public function new(jsFunc:Dynamic) {
		super();
		this.jsFunc = jsFunc;
		this.layout = null;
	}

	public function get isArrayInput():Bool {
		return /^\((\s+)?\[/.test(jsFunc.toString());
	}

	public function setLayout(layout:Dynamic):Dynamic {
		this.layout = layout;
		return this;
	}

	public function call(inputs:Array<Dynamic> = null):Dynamic {
		nodeObjects(inputs);
		return nodeObject(new ShaderCallNodeInternal(this, inputs));
	}

	public function setup():Dynamic {
		return call();
	}
}

enum NodeType {
	BOOL;
	FLOAT;
	INT;
	UINT;
}

var bools:Array<Bool> = [false, true];
var uints:Array<Int> = [0, 1, 2, 3];
var ints:Array<Int> = [-1, -2];
var floats:Array<Float> = [0.5, 1.5, 1 / 3, 1e-6, 1e6, Math.PI, Math.PI * 2, 1 / Math.PI, 2 / Math.PI, 1 / (Math.PI * 2), Math.PI / 2];

var boolsCacheMap:Map<Bool, ConstNode> = new Map();
for (bool in bools) {
	boolsCacheMap.set(bool, new ConstNode(bool));
}

var uintsCacheMap:Map<Int, ConstNode> = new Map();
for (uint in uints) {
	uintsCacheMap.set(uint, new ConstNode(uint, "uint"));
}

var intsCacheMap:Map<Int, ConstNode> = new Map(uintsCacheMap.map(el => new ConstNode(el.value, "int")));
for (int in ints) {
	intsCacheMap.set(int, new ConstNode(int, "int"));
}

var floatsCacheMap:Map<Float, ConstNode> = new Map(intsCacheMap.map(el => new ConstNode(el.value)));
for (float in floats) {
	floatsCacheMap.set(float, new ConstNode(float));
}
for (float in floats) {
	floatsCacheMap.set(-float, new ConstNode(-float));
}

var cacheMaps:Map<NodeType, Map<Dynamic, ConstNode>> = new Map([
	[NodeType.BOOL, boolsCacheMap],
	[NodeType.UINT, uintsCacheMap],
	[NodeType.INT, intsCacheMap],
	[NodeType.FLOAT, floatsCacheMap]
]);

var constNodesCacheMap:Map<Dynamic, ConstNode> = new Map(boolsCacheMap.keyValueIter().concat(floatsCacheMap.keyValueIter()));

function getConstNode(value:Dynamic, type:Null<String>):ConstNode {
	if (constNodesCacheMap.exists(value)) {
		return constNodesCacheMap.get(value);
	} else if (value.isNode == true) {
		return cast(value, ConstNode);
	} else {
		return new ConstNode(value, type);
	}
}

function safeGetNodeType(node:Dynamic):Null<String> {
	try {
		return node.getNodeType();
	} catch (e:Dynamic) {
		return null;
	}
}

class ConvertType {
	public var type:String;
	public var cacheMap:Null<Map<Dynamic, ConstNode>>;

	public function new(type:String, cacheMap:Null<Map<Dynamic, ConstNode>> = null) {
		this.type = type;
		this.cacheMap = cacheMap;
	}

	public function toNode(params:Array<Dynamic>):Dynamic {
		if (params.length == 0 || (!["bool", "float", "int", "uint"].contains(type) && params.every(param => typeof param != "object"))) {
			params = [getValueFromType(type, params)];
		}
		if (params.length == 1 && cacheMap != null && cacheMap.exists(params[0])) {
			return nodeObject(cacheMap.get(params[0]));
		}
		if (params.length == 1) {
			var node = getConstNode(params[0], type);
			if (safeGetNodeType(node) == type) {
				return nodeObject(node);
			}
			return nodeObject(new ConvertNode(nodeObject(node), type));
		}
		var nodes = params.map(param => getConstNode(param));
		return nodeObject(new JoinNode(nodes, type));
	}
}

// exports

function defined(value:Dynamic):Dynamic {
	return value && value.value;
}

// utils

function getConstNodeType(value:Dynamic):Null<String> {
	return (value != null) ? (value.nodeType || value.convertTo || (typeof value == "string" ? value : null)) : null;
}

// shader node base

function ShaderNode(jsFunc:Dynamic):Dynamic {
	return new ShaderNodeInternal(jsFunc);
}

function nodeObject(val:Dynamic, altType:Null<String> = null):Dynamic {
	return new ShaderNodeObject(val, altType).toNode();
}

function nodeObjects(val:Dynamic, altType:Null<String> = null):Dynamic {
	return new ShaderNodeObjects(val, altType).toNode();
}

function nodeArray(val:Array<Dynamic>, altType:Null<String> = null):Array<Dynamic> {
	return new ShaderNodeArray(val, altType).toNode();
}

function nodeProxy(NodeClass:Dynamic, ...params:Array<Dynamic>):Dynamic {
	return new ShaderNodeProxy(NodeClass, params[0], params[1], params[2]).toNode(params.slice(3));
}

function nodeImmutable(NodeClass:Dynamic, ...params:Array<Dynamic>):Dynamic {
	return new ShaderNodeImmutable(NodeClass, params).toNode();
}

function tslFn(jsFunc:Dynamic):Dynamic {
	var shaderNode = new ShaderNode(jsFunc);
	var fn = function(...params:Array<Dynamic>):Dynamic {
		var inputs:Array<Dynamic>;
		nodeObjects(params);
		if (params[0] && params[0].isNode) {
			inputs = [...params];
		} else {
			inputs = params[0];
		}
		return shaderNode.call(inputs);
	};
	fn.shaderNode = shaderNode;
	fn.setLayout = function(layout:Dynamic):Dynamic {
		shaderNode.setLayout(layout);
		return fn;
	};
	return fn;
}

//

var currentStack:Dynamic = null;

function setCurrentStack(stack:Dynamic):Void {
	if (currentStack == stack) {
		//throw new Error( 'Stack already defined.' );
	}
	currentStack = stack;
}

function getCurrentStack():Dynamic {
	return currentStack;
}

function If(...params:Array<Dynamic>):Dynamic {
	return currentStack.if(...params);
}

function append(node:Dynamic):Dynamic {
	if (currentStack) {
		currentStack.add(node);
	}
	return node;
}

// types
// @TODO: Maybe export from ConstNode.js?

var color = new ConvertType("color");

var float = new ConvertType("float", cacheMaps.get(NodeType.FLOAT));
var int = new ConvertType("int", cacheMaps.get(NodeType.INT));
var uint = new ConvertType("uint", cacheMaps.get(NodeType.UINT));
var bool = new ConvertType("bool", cacheMaps.get(NodeType.BOOL));

var vec2 = new ConvertType("vec2");
var ivec2 = new ConvertType("ivec2");
var uvec2 = new ConvertType("uvec2");
var bvec2 = new ConvertType("bvec2");

var vec3 = new ConvertType("vec3");
var ivec3 = new ConvertType("ivec3");
var uvec3 = new ConvertType("uvec3");
var bvec3 = new ConvertType("bvec3");

var vec4 = new ConvertType("vec4");
var ivec4 = new ConvertType("ivec4");
var uvec4 = new ConvertType("uvec4");
var bvec4 = new ConvertType("bvec4");

var mat2 = new ConvertType("mat2");
var imat2 = new ConvertType("imat2");
var umat2 = new ConvertType("umat2");
var bmat2 = new ConvertType("bmat2");

var mat3 = new ConvertType("mat3");
var imat3 = new ConvertType("imat3");
var umat3 = new ConvertType("umat3");
var bmat3 = new ConvertType("bmat3");

var mat4 = new ConvertType("mat4");
var imat4 = new ConvertType("imat4");
var umat4 = new ConvertType("umat4");
var bmat4 = new ConvertType("bmat4");

function string(value:String = ""):Dynamic {
	return nodeObject(new ConstNode(value, "string"));
}

function arrayBuffer(value:Dynamic):Dynamic {
	return nodeObject(new ConstNode(value, "ArrayBuffer"));
}

// basic nodes
// HACK - we cannot export them from the corresponding files because of the cyclic dependency
var element = nodeProxy(ArrayElementNode);
function convert(node:Dynamic, types:String):Dynamic {
	return nodeObject(new ConvertNode(nodeObject(node), types));
}
function split(node:Dynamic, channels:String):Dynamic {
	return nodeObject(new SplitNode(nodeObject(node), channels));
}