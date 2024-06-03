import js.Browser;
import js.RegExp;
import js.Array;
import js.Boot;
import NodeFunction from '../../../nodes/core/NodeFunction.hx';
import NodeFunctionInput from '../../../nodes/core/NodeFunctionInput.hx';

class WGSLNodeFunction extends NodeFunction {
    var inputsCode: String;
    var blockCode: String;

    public function new(source: String) {
        var parsed = parse(source);
        super(parsed.type, parsed.inputs, parsed.name);
        this.inputsCode = parsed.inputsCode;
        this.blockCode = parsed.blockCode;
    }

    public function getCode(name: String = null): String {
        if (name == null) name = this.name;
        var type = this.type != 'void' ? '-> ' + this.type : '';
        return `fn ${name} ( ${this.inputsCode.trim()} ) ${type}${this.blockCode}`;
    }
}

class ParseResult {
    public var type: String;
    public var inputs: Array<NodeFunctionInput>;
    public var name: String;
    public var inputsCode: String;
    public var blockCode: String;
}

var declarationRegexp: RegExp = new RegExp("^[fn]*\\s*([a-z_0-9]+)?\\s*\\(([\\s\\S]*?)\\)\\s*[\\-\\>]*\\s*([a-z_0-9]+)?", "i");
var propertiesRegexp: RegExp = new RegExp("[a-z_0-9]+|<(.*?)>+", "ig");

var wgslTypeLib: haxe.ds.StringMap<String> = new haxe.ds.StringMap<String>();
wgslTypeLib.set('f32', 'float');

function parse(source: String): ParseResult {
    source = source.trim();
    var declaration = source.match(declarationRegexp);
    if (declaration != null && declaration.length == 4) {
        var inputsCode = declaration[2];
        var propsMatches: Array<Array<String>> = [];
        var nameMatch: Array<String>;
        while ((nameMatch = propertiesRegexp.exec(inputsCode)) != null) {
            propsMatches.push(nameMatch);
        }
        var inputs: Array<NodeFunctionInput> = [];
        var i: Int = 0;
        while (i < propsMatches.length) {
            var name = propsMatches[i++][0];
            var type = propsMatches[i++][0];
            if (wgslTypeLib.exists(type)) type = wgslTypeLib.get(type);
            if (i < propsMatches.length && propsMatches[i][0].indexOf('<') == 0) i++;
            inputs.push(new NodeFunctionInput(type, name));
        }
        var blockCode = source.substring(declaration[0].length);
        var name = declaration[1] != null ? declaration[1] : '';
        var type = declaration[3] != null ? declaration[3] : 'void';
        var result = new ParseResult();
        result.type = type;
        result.inputs = inputs;
        result.name = name;
        result.inputsCode = inputsCode;
        result.blockCode = blockCode;
        return result;
    } else {
        throw new js.Error('FunctionNode: Function is not a WGSL code.');
    }
}

export default WGSLNodeFunction;