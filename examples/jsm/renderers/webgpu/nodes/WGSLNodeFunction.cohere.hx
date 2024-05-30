import NodeFunction from '../nodes/core/NodeFunction.hx';
import NodeFunctionInput from '../nodes/core/NodeFunctionInput.hx';

var declarationRegexp = ~'^[fn]*\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)\s*[\-\>]*\s*([a-z_0-9]+)?/i';
var propertiesRegexp = ~'[a-z_0-9]+|<(.*?)>+/ig';

var wgslTypeLib = { 'f32': 'Float' };

function parse(source) {
	source = source.trim();
	var declaration = declarationRegexp.match(source);
	if (declaration != null && declaration.length == 4) {
		// tokenizer
		var inputsCode = declaration[2];
		var propsMatches = [];
		var nameMatch = null;
		while (nameMatch = propertiesRegexp.exec(inputsCode)) {
			propsMatches.push(nameMatch);
		}
		// parser
		var inputs = [];
		var i = 0;
		while (i < propsMatches.length) {
			// default
			var name = propsMatches[i++][0];
			var type = propsMatches[i++][0];
			type = wgslTypeLib.get(type) ?? type;
			// precision
			if (i < propsMatches.length && propsMatches[i][0].startsWith('<')) i++;
			// add input
			inputs.push(NodeFunctionInput(type, name));
		}
		//
		var blockCode = source.substring(declaration[0].length);
		var name = declaration[1] != null ? declaration[1] : '';
		var type = declaration[3] ?? 'Void';
		return {
			type: Type.ofDynamic(type),
			inputs: inputs,
			name: name,
			inputsCode: inputsCode,
			blockCode: blockCode
		};
	} else {
		throw haxe.Exception('FunctionNode: Function is not a WGSL code.');
	}
}

class WGSLNodeFunction extends NodeFunction {
	public var inputsCode:String;
	public var blockCode:String;

	public function new(source) {
		var data = parse(source);
		super(data.type, data.inputs, data.name);
		this.inputsCode = data.inputsCode;
		this.blockCode = data.blockCode;
	}

	public function getCode(name = this.name) {
		var type = this.type != Void ? '-> ' + Type.getFullName(this.type) : '';
		return 'fn ' + name + ' (' + this.inputsCode.trim() + ') ' + type + this.blockCode;
	}
}

class haxe_ds_StringMap<T> extends haxe_ds_HashMap {
}