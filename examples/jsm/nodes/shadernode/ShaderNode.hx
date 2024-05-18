import haxe.ds.Map;
import haxe.ds.WeakMap;

class ShaderNodeHandler {
	public function setup(NodeClosure:Dynamic, params:Array<Dynamic>):Dynamic {
		return NodeClosure(nodeObjects(params.shift()), ...params);
	}

	public function get(node:Dynamic, prop:String, nodeObj:Dynamic):Dynamic {
		if (Type.typeof(prop) == haxe.EnumType.Enum && prop == "r" || prop == "s") prop = "x";
		else if (Type.typeof(prop) == haxe.EnumType.Enum && prop == "g" || prop == "t") prop = "y";
		else if (Type.typeof(prop) == haxe.EnumType.Enum && prop == "b" || prop == "p") prop = "z";
		else if (Type.typeof(prop) == haxe.EnumType.Enum && prop == "a" || prop == "q") prop = "w";

		if (node.isStackNode !== true && prop == "assign") {
			return (...params:Array<Dynamic>) -> {
				currentStack.assign(nodeObj, ...params);
				return nodeObj;
			};
		} else if (NodeElements.has(prop)) {
			const nodeElement = NodeElements.get(prop);
			return node.isStackNode ? (...params:Array<Dynamic>) -> nodeObj.add(nodeElement(...params)) : (...params:Array<Dynamic>) -> nodeElement(nodeObj, ...params);
		} else if (prop == "self") {
			return node;
		} else if (prop.endsWith("Assign") && NodeElements.has(prop.slice(0, prop.length - "Assign".length))) {
			const nodeElement = NodeElements.get(prop.slice(0, prop.length - "Assign".length));
			return node.isStackNode ? (...params:Array<Dynamic>) -> nodeObj.assign(params[0], nodeElement(...params)) : (...params:Array<Dynamic>) -> nodeObj.assign(nodeElement(nodeObj, ...params));
		} else if (/^[xyzwrgbastpq]{1,4}$/.test(prop) === true) {
			// accessing properties (swizzle)
			prop = parseSwizzle(prop);
			return nodeObject(new SplitNode(nodeObj, prop));
		} else if (/^set[XYZWRGBASTPQ]{1,4}$/.test(prop) === true) {
			// set properties (swizzle)
			prop = parseSwizzle(prop.slice(3).toLowerCase());
			// sort to xyzw sequence
			prop = prop.split("").sort().join("");
			return (value:Dynamic) -> nodeObject(new SetNode(node, prop, value));
		} else if (prop == "width" || prop == "height" || prop == "depth") {
			// accessing property
			if (prop == "width") prop = "x";
			else if (prop == "height") prop = "y";
			else if (prop == "depth") prop = "z";
			return nodeObject(new SplitNode(nodeObj, prop));
		} else if (/^\d+$/.test(prop) === true) {
			// accessing array
			return nodeObject(new ArrayElementNode(nodeObj, new ConstNode(Number(prop), "uint")));
		}

		return Reflect.getProperty(node, prop, nodeObj);
	}

	public function set(node:Dynamic, prop:String, value:Dynamic, nodeObj:Dynamic):Bool {
		if (Type.typeof(prop) == haxe.EnumType.Enum && /^[xyzwrgbastpq]{1,4}$/.test(prop) === true || prop == "width" || prop == "height" || prop == "depth" || /^\d+$/.test(prop) === true) {
			nodeObj[prop].assign(value);
			return true;
		}
		return Reflect.setProperty(node, prop, value, nodeObj);
	}
}

// ... (other parts of the code)

var currentStack:Dynamic;
var NodeElements:Map<String,Dynamic>;

function addNodeElement(name:String, nodeElement:Dynamic):Void {
	if (NodeElements.has(name)) {
		console.warn("Redefinition of node element " + name);
		return;
	}

	if (typeof nodeElement != "function") throw new Error("Node element " + name + " is not a function");

	NodeElements.set(name, nodeElement);
}

function parseSwizzle(props:String):String {
	return props.replace(/r|s/g, "x").replace(/g|t/g, "y").replace(/b|p/g, "z").replace(/a|q/g, "w");
}

// ... (other parts of the code)

// exports

// utils

export function getConstNodeType(value:Dynamic):String {
	if (value != undefined && value != null) return (value.nodeType || value.convertTo || (Type.typeof(value) == haxe.EnumType.Enum ? value.toString() : null));
	return null;
}

// shader node base

export function ShaderNode(jsFunc:Dynamic):Dynamic {
	return new Proxy(new ShaderNodeInternal(jsFunc), shaderNodeHandler);
}

// ... (other parts of the code)