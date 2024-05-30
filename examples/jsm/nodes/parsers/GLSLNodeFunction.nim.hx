import NodeFunction from '../core/NodeFunction.js';
import NodeFunctionInput from '../core/NodeFunctionInput.js';

class GLSLNodeFunction extends NodeFunction {

    private static var declarationRegexp:EReg = ~/^\s*(highp|mediump|lowp)?\s*([a-z_0-9]+)\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)/i;
    private static var propertiesRegexp:EReg = ~/[a-z_0-9]+/ig;

    private static var pragmaMain:String = '#pragma main';

    private static function parse(source:String):Dynamic {

        source = source.trim();

        var pragmaMainIndex:Int = source.indexOf(pragmaMain);

        var mainCode:String = pragmaMainIndex != -1 ? source.slice(pragmaMainIndex + pragmaMain.length) : source;

        var declaration:Array<String> = mainCode.match(declarationRegexp);

        if (declaration != null && declaration.length == 5) {

            // tokenizer

            var inputsCode:String = declaration[4];
            var propsMatches:Array<String> = [];

            var nameMatch:String = null;

            while ((nameMatch = propertiesRegexp.match(inputsCode)) != null) {

                propsMatches.push(nameMatch);

            }

            // parser

            var inputs:Array<NodeFunctionInput> = [];

            var i:Int = 0;

            while (i < propsMatches.length) {

                var isConst:Bool = propsMatches[i][0] == 'const';

                if (isConst) {

                    i++;

                }

                var qualifier:String = propsMatches[i][0];

                if (qualifier == 'in' || qualifier == 'out' || qualifier == 'inout') {

                    i++;

                } else {

                    qualifier = '';

                }

                var type:String = propsMatches[i++][0];

                var count:Null<Int> = Std.parseInt(propsMatches[i][0]);

                if (!Std.is(count, NaN)) i++;
                else count = null;

                var name:String = propsMatches[i++][0];

                inputs.push(new NodeFunctionInput(type, name, count, qualifier, isConst));

            }

            //

            var blockCode:String = mainCode.substring(declaration[0].length);

            var name:String = declaration[3] != null ? declaration[3] : '';
            var type:String = declaration[2];

            var presicion:String = declaration[1] != null ? declaration[1] : '';

            var headerCode:String = pragmaMainIndex != -1 ? source.slice(0, pragmaMainIndex) : '';

            return {
                type,
                inputs,
                name,
                presicion,
                inputsCode,
                blockCode,
                headerCode
            };

        } else {

            throw new Error('FunctionNode: Function is not a GLSL code.');

        }

    }

    public function new(source:String) {

        var { type, inputs, name, presicion, inputsCode, blockCode, headerCode } = parse(source);

        super(type, inputs, name, presicion);

        this.inputsCode = inputsCode;
        this.blockCode = blockCode;
        this.headerCode = headerCode;

    }

    public function getCode(name:String = this.name):String {

        var code:String;

        var blockCode:String = this.blockCode;

        if (blockCode != '') {

            var { type, inputsCode, headerCode, presicion } = this;

            var declarationCode:String = `${ type } ${ name } ( ${ inputsCode.trim() } )`;

            if (presicion != '') {

                declarationCode = `${ presicion } ${ declarationCode }`;

            }

            code = headerCode + declarationCode + blockCode;

        } else {

            // interface function

            code = '';

        }

        return code;

    }

}