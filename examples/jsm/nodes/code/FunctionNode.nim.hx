import CodeNode from './CodeNode.js';
import { addNodeClass } from '../core/Node.js';
import { nodeObject } from '../shadernode/ShaderNode.js';

class FunctionNode extends CodeNode {

	public var keywords:Map<String, Dynamic>;

	public function new(code:String = "", includes:Array<Dynamic>, language:String = "") {

		super(code, includes, language);

		this.keywords = new Map();

	}

	public function getNodeType(builder:Dynamic):Dynamic {

		return this.getNodeFunction(builder).type;

	}

	public function getInputs(builder:Dynamic):Dynamic {

		return this.getNodeFunction(builder).inputs;

	}

	public function getNodeFunction(builder:Dynamic):Dynamic {

		var nodeData = builder.getDataFromNode(this);

		var nodeFunction = nodeData.nodeFunction;

		if (nodeFunction == null) {

			nodeFunction = builder.parser.parseFunction(this.code);

			nodeData.nodeFunction = nodeFunction;

		}

		return nodeFunction;

	}

	public function generate(builder:Dynamic, output:String):Dynamic {

		super.generate(builder);

		var nodeFunction = this.getNodeFunction(builder);

		var name = nodeFunction.name;
		var type = nodeFunction.type;

		var nodeCode = builder.getCodeFromNode(this, type);

		if (name != "") {

			// use a custom property name

			nodeCode.name = name;

		}

		var propertyName = builder.getPropertyName(nodeCode);

		var code = this.getNodeFunction(builder).getCode(propertyName);

		var keywords = this.keywords;
		var keywordsProperties = keywords.keys();

		if (keywordsProperties.length > 0) {

			for (property in keywordsProperties) {

				var propertyRegExp = new EReg(`\\b${property}\\b`, 'g');
				var nodeProperty = keywords[property].build(builder, 'property');

				code = code.replace(propertyRegExp, nodeProperty);

			}

		}

		nodeCode.code = code + '\n';

		if (output == 'property') {

			return propertyName;

		} else {

			return builder.format(`${propertyName}()`, type, output);

		}

	}

}

export default FunctionNode;

function nativeFn(code:String, includes:Array<Dynamic> = [], language:String = ""):Dynamic {

	for (i in 0...includes.length) {

		var include = includes[i];

		// TSL Function: glslFn, wgslFn

		if (Std.is(include, Function)) {

			includes[i] = include.functionNode;

		}

	}

	var functionNode = nodeObject(new FunctionNode(code, includes, language));

	var fn = function(...params) return functionNode.call(params);
	fn.functionNode = functionNode;

	return fn;

}

export function glslFn(code:String, includes:Array<Dynamic>):Dynamic {

	return nativeFn(code, includes, 'glsl');

}

export function wgslFn(code:String, includes:Array<Dynamic>):Dynamic {

	return nativeFn(code, includes, 'wgsl');

}

addNodeClass('FunctionNode', FunctionNode);