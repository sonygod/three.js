package three.js.examples.jsm.nodes.parsers;

import three.js.core.NodeFunction;
import three.js.core.NodeFunctionInput;

class GLSLNodeFunction extends NodeFunction {
    private var inputsCode:String;
    private var blockCode:String;
    private var headerCode:String;

    private static var declarationRegexp:EReg = ~/^\s*(highp|mediump|lowp)?\s*([a-z_0-9]+)\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)/i;
    private static var propertiesRegexp:EReg = ~/[a-z_0-9]+/ig;

    private static var pragmaMain:String = '#pragma main';

    public function new(source:String) {
        var parsedSource = GLSLNodeFunction.parse(source);
        super(parsedSource.type, parsedSource.inputs, parsedSource.name, parsedSource.presicion);
        this.inputsCode = parsedSource.inputsCode;
        this.blockCode = parsedSource.blockCode;
        this.headerCode = parsedSource.headerCode;
    }

    public function getCode(?name:String):String {
        if (name == null) name = this.name;
        var code:String;
        if (this.blockCode != '') {
            var declarationCode = '${this.type} $name (${this.inputsCode.trim()})';
            if (this.presicion != '') {
                declarationCode = '${this.presicion} $declarationCode';
            }
            code = this.headerCode + declarationCode + this.blockCode;
        } else {
            code = '';
        }
        return code;
    }

    private static function parse(source:String):{type:String, inputs:Array<NodeFunctionInput>, name:String, presicion:String, inputsCode:String, blockCode:String, headerCode:String} {
        source = StringTools.trim(source);
        var pragmaMainIndex = source.indexOf(pragmaMain);
        var mainCode = if (pragmaMainIndex != -1) source.substring(pragmaMainIndex + pragmaMain.length) else source;
        var declaration = declarationRegexp.match(mainCode);
        if (declaration != null && declaration.length == 5) {
            var inputsCode = declaration[4];
            var propsMatches = [];
            var nameMatch;
            while ((nameMatch = propertiesRegexp.exec(inputsCode)) != null) {
                propsMatches.push(nameMatch);
            }
            var inputs = [];
            var i = 0;
            while (i < propsMatches.length) {
                var isConst = propsMatches[i][0] == 'const';
                if (isConst) {
                    i++;
                }
                var qualifier = propsMatches[i][0];
                if (qualifier == 'in' || qualifier == 'out' || qualifier == 'inout') {
                    i++;
                } else {
                    qualifier = '';
                }
                var type = propsMatches[i++][0];
                var count;
                if (!Math.isNaN(Std.parseInt(propsMatches[i][0]))) {
                    i++;
                    count = Std.parseInt(propsMatches[i - 1][0]);
                } else {
                    count = null;
                }
                var name = propsMatches[i++][0];
                inputs.push(new NodeFunctionInput(type, name, count, qualifier, isConst));
            }
            var blockCode = mainCode.substring(declaration[0].length);
            var name = if (declaration[3] != null) declaration[3] else '';
            var type = declaration[2];
            var presicion = if (declaration[1] != null) declaration[1] else '';
            var headerCode = if (pragmaMainIndex != -1) source.substring(0, pragmaMainIndex) else '';
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
            throw new Error('FunctionNode: Function is not a GLSL code.');
        }
    }
}