import NodeFunction from '../core/NodeFunction.hx';
import NodeFunctionInput from '../core/NodeFunctionInput.hx';

var declarationRegexp = ~'^\s*(highp|mediump|lowp)?\s*([a-z_0-9]+)\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)/i';
var propertiesRegexp = ~'[a-z_0-9]+/ig';

var pragmaMain = '#pragma main';

function parse(source) {
    source = source.trim();
    var pragmaMainIndex = source.indexOf(pragmaMain);
    var mainCode = pragmaMainIndex != -1 ? source.substr(pragmaMainIndex + pragmaMain.length) : source;
    var declaration = mainCode.match(declarationRegexp);
    if (declaration != null && declaration.length == 5) {
        // tokenizer
        var inputsCode = declaration[4];
        var propsMatches = [];
        var nameMatch = null;
        while (nameMatch = propertiesRegexp.exec(inputsCode)) {
            propsMatches.push(nameMatch);
        }
        // parser
        var inputs = [];
        var i = 0;
        while (i < propsMatches.length) {
            var isConst = propsMatches[i][0] == 'const';
            if (isConst) {
                i++;
            }
            var qualifier = propsMatches[i][0];
            if (['in', 'out', 'inout'].contains(qualifier)) {
                i++;
            } else {
                qualifier = '';
            }
            var type = propsMatches[i++][0];
            var count = Std.parseInt(propsMatches[i][0]);
            if (count == Std.int(count)) {
                i++;
            } else {
                count = null;
            }
            var name = propsMatches[i++][0];
            inputs.push(NodeFunctionInput(type, name, count, qualifier, isConst));
        }
        //
        var blockCode = mainCode.substring(declaration[0].length);
        var name = declaration[3] != null ? declaration[3] : '';
        var type = declaration[2];
        var presicion = declaration[1] != null ? declaration[1] : '';
        var headerCode = pragmaMainIndex != -1 ? source.substr(0, pragmaMainIndex) : '';
        return {
            type: type,
            inputs: inputs,
            name: name,
            presicion: presicion,
            inputsCode: inputsCode,
            blockCode: blockCode,
            headerCode: headerCode
        };
    } else {
        throw haxe.Exception('FunctionNode: Function is not a GLSL code.');
    }
}

class GLSLNodeFunction extends NodeFunction {
    function new(source) {
        var data = parse(source);
        super(data.type, data.inputs, data.name, data.presicion);
        this.inputsCode = data.inputsCode;
        this.blockCode = data.blockCode;
        this.headerCode = data.headerCode;
    }
    function getCode(name = this.name) {
        var code;
        var blockCode = this.blockCode;
        if (blockCode != '') {
            var data = { type: this.type, inputsCode: this.inputsCode, headerCode: this.headerCode, presicion: this.presicion };
            var declarationCode = "${data.type} ${name} (${data.inputsCode.trim()})";
            if (data.presicion != '') {
                declarationCode = "${data.presicion} ${declarationCode}";
            }
            code = data.headerCode + declarationCode + blockCode;
        } else {
            // interface function
            code = '';
        }
        return code;
    }
}

class js__$GLSLNodeFunction_GLSLNodeFunction_$Impl_ {
}

export { GLSLNodeFunction };