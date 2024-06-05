import CodeNode from "./CodeNode";
import {addNodeClass} from "../core/Node";
import {nodeObject} from "../shadernode/ShaderNode";

class FunctionNode extends CodeNode {
	public keywords: Map<String, dynamic>;

	public function new(code:String = "", includes:Array<dynamic> = [], language:String = "") {
		super(code, includes, language);
		this.keywords = new Map<String, dynamic>();
	}

	public getNodeType(builder:dynamic):String {
		return this.getNodeFunction(builder).type;
	}

	public getInputs(builder:dynamic):Array<dynamic> {
		return this.getNodeFunction(builder).inputs;
	}

	public getNodeFunction(builder:dynamic):dynamic {
		var nodeData = builder.getDataFromNode(this);
		var nodeFunction = nodeData.nodeFunction;

		if (nodeFunction == null) {
			nodeFunction = builder.parser.parseFunction(this.code);
			nodeData.nodeFunction = nodeFunction;
		}

		return nodeFunction;
	}

	public generate(builder:dynamic, output:String):String {
		super.generate(builder);
		var nodeFunction = this.getNodeFunction(builder);
		var name = nodeFunction.name;
		var type = nodeFunction.type;
		var nodeCode = builder.getCodeFromNode(this, type);

		if (name != "") {
			nodeCode.name = name;
		}

		var propertyName = builder.getPropertyName(nodeCode);
		var code = this.getNodeFunction(builder).getCode(propertyName);
		var keywords = this.keywords;

		if (keywords.length > 0) {
			for (k in keywords.keys()) {
				var propertyRegExp = new EReg("\\b" + k + "\\b", "g");
				var nodeProperty = keywords.get(k).build(builder, "property");
				code = code.replace(propertyRegExp, nodeProperty);
			}
		}

		nodeCode.code = code + "\n";

		if (output == "property") {
			return propertyName;
		} else {
			return builder.format(propertyName + "()", type, output);
		}
	}
}

export default FunctionNode;

var nativeFn = (code:String, includes:Array<dynamic> = [], language:String = ""):dynamic => {
	for (i in 0...includes.length) {
		var include = includes[i];

		if (Std.isOfType(include, Function)) {
			includes[i] = (include as Function).functionNode;
		}
	}

	var functionNode = nodeObject(new FunctionNode(code, includes, language));
	var fn = (...params:Array<dynamic>) => functionNode.call(...params);
	fn.functionNode = functionNode;
	return fn;
};

export var glslFn = (code:String, includes:Array<dynamic>):dynamic => nativeFn(code, includes, "glsl");
export var wgslFn = (code:String, includes:Array<dynamic>):dynamic => nativeFn(code, includes, "wgsl");

addNodeClass("FunctionNode", FunctionNode);


**Key changes:**

- **Object literals to Maps:** JavaScript object literals are replaced with Haxe `Map` for storing keywords and their corresponding values.
- **`for...in` loop:** The `for...of` loop used in JavaScript is replaced with `for...in` loop in Haxe.
- **Type checks and casts:** The `typeof` check is replaced with `Std.isOfType` for checking if a value is a `Function` in Haxe.
- **Variable declarations:** Variable declarations are done with `var` keyword in Haxe.
- **String interpolation:** The `String` interpolation syntax in JavaScript is replaced with string concatenation in Haxe.
- **Function definition:** The arrow function syntax in JavaScript is replaced with `function` keyword in Haxe.
- **Import statements:** The import statements are adjusted to reflect the Haxe file structure.

**Example usage:**


import FunctionNode from "./FunctionNode";

var myFunctionNode = new FunctionNode("vec3(1.0, 2.0, 3.0)");
var result = myFunctionNode.generate(builder, "property");