import NodeFunction from '../core/NodeFunction';
import NodeFunctionInput from '../core/NodeFunctionInput';

class GLSLNodeFunction extends NodeFunction {
    var declarationRegexp:EReg = new EReg("^\\s*(highp|mediump|lowp)?\\s*([a-z_0-9]+)\\s*([a-z_0-9]+)?\\s*\\(([\\s\\S]*?)\\)", "i");
    var propertiesRegexp:EReg = new EReg("[a-z_0-9]+", "ig");

    var pragmaMain:String = '#pragma main';

    var inputsCode:String;
    var blockCode:String;
    var headerCode:String;

    public function new(source:String) {
        super();

        var parsed = parse(source);

        this.type = parsed.type;
        this.inputs = parsed.inputs;
        this.name = parsed.name;
        this.presicion = parsed.presicion;
        this.inputsCode = parsed.inputsCode;
        this.blockCode = parsed.blockCode;
        this.headerCode = parsed.headerCode;
    }

    public function getCode(name:String = null):String {
        if (name == null) {
            name = this.name;
        }

        var code:String;

        if (this.blockCode != '') {
            var declarationCode = "${this.type} ${name} ( ${this.inputsCode.trim()} )";

            if (this.presicion != '') {
                declarationCode = "${this.presicion} ${declarationCode}";
            }

            code = this.headerCode + declarationCode + this.blockCode;
        } else {
            code = '';
        }

        return code;
    }
}

function parse(source:String):Dynamic {
    source = source.trim();

    var pragmaMainIndex = source.indexOf(pragmaMain);

    var mainCode = pragmaMainIndex != -1 ? source.substr(pragmaMainIndex + pragmaMain.length) : source;

    var declaration = declarationRegexp.match(mainCode);

    if (declaration != null && declaration.length == 5) {
        var inputsCode = declaration[4];
        var propsMatches:Array<ERegMatch> = [];

        var nameMatch:ERegMatch = null;

        while ((nameMatch = propertiesRegexp.exec(inputsCode)) != null) {
            propsMatches.push(nameMatch);
        }

        var inputs:Array<NodeFunctionInput> = [];

        var i:Int = 0;

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

            var count:Int = Std.parseInt(propsMatches[i][0]);

            if (!Std.isNaN(count)) {
                i++;
            } else {
                count = null;
            }

            var name = propsMatches[i++][0];

            inputs.push(new NodeFunctionInput(type, name, count, qualifier, isConst));
        }

        var blockCode = mainCode.substr(declaration[0].length);

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
        throw "FunctionNode: Function is not a GLSL code.";
    }
}