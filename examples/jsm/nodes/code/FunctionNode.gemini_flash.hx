import CodeNode from "./CodeNode";
import {addNodeClass} from "../core/Node";
import {nodeObject} from "../shadernode/ShaderNode";

class FunctionNode extends CodeNode {
	public keywords: Map<String, dynamic> = new Map();

	public function new(code: String = "", includes: Array<dynamic> = [], language: String = "") {
		super(code, includes, language);
	}

	public getNodeType(builder: dynamic): String {
		return this.getNodeFunction(builder).type;
	}

	public getInputs(builder: dynamic): Array<dynamic> {
		return this.getNodeFunction(builder).inputs;
	}

	public getNodeFunction(builder: dynamic): dynamic {
		var nodeData = builder.getDataFromNode(this);
		var nodeFunction = nodeData.nodeFunction;

		if (nodeFunction == null) {
			nodeFunction = builder.parser.parseFunction(this.code);
			nodeData.nodeFunction = nodeFunction;
		}

		return nodeFunction;
	}

	public generate(builder: dynamic, output: String): String {
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
		var keywordsProperties = keywords.keys();

		if (keywordsProperties.length > 0) {
			for (property in keywordsProperties) {
				var propertyRegExp = new EReg(`\\b${property}\\b`, "g");
				var nodeProperty = keywords.get(property).build(builder, "property");
				code = code.replace(propertyRegExp, nodeProperty);
			}
		}

		nodeCode.code = code + "\n";

		if (output == "property") {
			return propertyName;
		} else {
			return builder.format(`${propertyName}()`, type, output);
		}
	}
}

export default FunctionNode;

var nativeFn = (code: String, includes: Array<dynamic> = [], language: String = "") -> dynamic {
	for (i in 0...includes.length) {
		var include = includes[i];

		// TSL Function: glslFn, wgslFn

		if (Std.isOfType(include, Function)) {
			includes[i] = include.functionNode;
		}
	}

	var functionNode = nodeObject(new FunctionNode(code, includes, language));

	var fn = (...params: Array<dynamic>) -> dynamic {
		return functionNode.call(...params);
	};

	fn.functionNode = functionNode;

	return fn;
};

export var glslFn = (code: String, includes: Array<dynamic>) -> dynamic {
	return nativeFn(code, includes, "glsl");
};

export var wgslFn = (code: String, includes: Array<dynamic>) -> dynamic {
	return nativeFn(code, includes, "wgsl");
};

addNodeClass("FunctionNode", FunctionNode);