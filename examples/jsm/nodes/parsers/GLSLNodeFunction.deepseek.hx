import three.js.examples.jsm.nodes.core.NodeFunction;
import three.js.examples.jsm.nodes.core.NodeFunctionInput;

class GLSLNodeFunction extends NodeFunction {

    static var declarationRegexp = /^\s*(highp|mediump|lowp)?\s*([a-z_0-9]+)\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)/i;
    static var propertiesRegexp = /[a-z_0-9]+/ig;

    static var pragmaMain = '#pragma main';

    static function parse(source:String):GLSLNodeFunction {

        source = source.trim();

        var pragmaMainIndex = source.indexOf(pragmaMain);

        var mainCode = pragmaMainIndex != -1 ? source.substr(pragmaMainIndex + pragmaMain.length) : source;

        var declaration = declarationRegexp.match(mainCode);

        if (declaration != null && declaration.length == 5) {

            // tokenizer

            var inputsCode = declaration[4];
            var propsMatches = [];

            var nameMatch = null;

            while ((nameMatch = propertiesRegexp.exec(inputsCode)) != null) {

                propsMatches.push(nameMatch);

            }

            // parser

            var inputs = [];

            var i = 0;

            while (i < propsMatches.length) {

                var isConst = propsMatches[i][0] == 'const';

                if (isConst == true) {

                    i++;

                }

                var qualifier = propsMatches[i][0];

                if (qualifier == 'in' || qualifier == 'out' || qualifier == 'inout') {

                    i++;

                } else {

                    qualifier = '';

                }

                var type = propsMatches[i++][0];

                var count = parseInt(propsMatches[i][0]);

                if (isNaN(count) == false) i++;
                else count = null;

                var name = propsMatches[i++][0];

                inputs.push(new NodeFunctionInput(type, name, count, qualifier, isConst));

            }

            //

            var blockCode = mainCode.substr(declaration[0].length);

            var name = declaration[3] != undefined ? declaration[3] : '';
            var type = declaration[2];

            var presicion = declaration[1] != undefined ? declaration[1] : '';

            var headerCode = pragmaMainIndex != -1 ? source.substr(0, pragmaMainIndex) : '';

            return new GLSLNodeFunction(type, inputs, name, presicion, inputsCode, blockCode, headerCode);

        } else {

            throw 'FunctionNode: Function is not a GLSL code.';

        }

    }

    var type:String;
    var inputs:Array<NodeFunctionInput>;
    var name:String;
    var presicion:String;
    var inputsCode:String;
    var blockCode:String;
    var headerCode:String;

    public function new(type:String, inputs:Array<NodeFunctionInput>, name:String, presicion:String, inputsCode:String, blockCode:String, headerCode:String) {

        super(type, inputs, name, presicion);

        this.inputsCode = inputsCode;
        this.blockCode = blockCode;
        this.headerCode = headerCode;

    }

    public function getCode(name:String = this.name):String {

        var code:String;

        var blockCode = this.blockCode;

        if (blockCode != '') {

            var type = this.type;
            var inputsCode = this.inputsCode;
            var headerCode = this.headerCode;
            var presicion = this.presicion;

            var declarationCode = `${type} ${name} ( ${inputsCode.trim()} )`;

            if (presicion != '') {

                declarationCode = `${presicion} ${declarationCode}`;

            }

            code = headerCode + declarationCode + blockCode;

        } else {

            // interface function

            code = '';

        }

        return code;

    }

}