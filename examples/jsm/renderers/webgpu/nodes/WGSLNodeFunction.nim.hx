import NodeFunction from '../../../nodes/core/NodeFunction.hx';
import NodeFunctionInput from '../../../nodes/core/NodeFunctionInput.hx';

class WGSLNodeFunction extends NodeFunction {

	private static var declarationRegexp:EReg = ~/^[fn]*\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)\s*[\-\>]*\s*([a-z_0-9]+)?/i;
	private static var propertiesRegexp:EReg = ~/[a-z_0-9]+|<(.*?)>+/ig;

	private static var wgslTypeLib:haxe.ds.StringMap<String> = new haxe.ds.StringMap();
	static {
		wgslTypeLib.set("f32", "float");
	}

	private static function parse(source:String):WGSLNodeFunctionData {

		source = source.trim();

		var declaration:Array<String> = declarationRegexp.match(source);

		if (declaration != null && declaration.length == 4) {

			// tokenizer

			var inputsCode:String = declaration[2];
			var propsMatches:Array<ERegMatch> = [];

			var nameMatch:ERegMatch = null;

			while ((nameMatch = propertiesRegexp.match(inputsCode)) != null) {

				propsMatches.push(nameMatch);

			}

			// parser

			var inputs:Array<NodeFunctionInput> = [];

			var i:Int = 0;

			while (i < propsMatches.length) {

				// default

				var name:String = propsMatches[i++][0];
				var type:String = propsMatches[i++][0];

				type = wgslTypeLib.get(type) || type;

				// precision

				if (i < propsMatches.length && propsMatches[i][0].startsWith('<') == true)
					i++;

				// add input

				inputs.push(new NodeFunctionInput(type, name));

			}

			//

			var blockCode:String = source.substring(declaration[0].length);

			var name:String = declaration[1] != null ? declaration[1] : '';
			var type:String = declaration[3] || 'void';

			return {
				type,
				inputs,
				name,
				inputsCode,
				blockCode
			};

		} else {

			throw new Error('FunctionNode: Function is not a WGSL code.');

		}

	}

	public function new(source:String) {

		var data:WGSLNodeFunctionData = parse(source);

		super(data.type, data.inputs, data.name);

		this.inputsCode = data.inputsCode;
		this.blockCode = data.blockCode;

	}

	public function getCode(name:String = this.name):String {

		var type:String = this.type != 'void' ? '-> ' + this.type : '';

		return 'fn ' + name + ' (' + this.inputsCode.trim() + ') ' + type + this.blockCode;

	}

}

typedef WGSLNodeFunctionData = {
	var type:String,
	var inputs:Array<NodeFunctionInput>,
	var name:String,
	var inputsCode:String,
	var blockCode:String
}