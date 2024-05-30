import three.examples.jsm.renderers.webgpu.nodes.NodeFunction;
import three.examples.jsm.renderers.webgpu.nodes.NodeFunctionInput;

class WGSLNodeFunction extends NodeFunction {

    static var declarationRegexp = /^[fn]*\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)\s*[\-\>]*\s*([a-z_0-9]+)?/i;
    static var propertiesRegexp = /[a-z_0-9]+|<(.*?)>+/ig;

    static var wgslTypeLib = {
        f32: 'float'
    };

    static function parse(source:String):Dynamic {

        source = source.trim();

        var declaration = declarationRegexp.match(source);

        if (declaration !== null && declaration.length == 4) {

            // tokenizer

            var inputsCode = declaration[2];
            var propsMatches = [];

            var nameMatch = null;

            while ((nameMatch = propertiesRegexp.exec(inputsCode)) !== null) {

                propsMatches.push(nameMatch);

            }

            // parser

            var inputs = [];

            var i = 0;

            while (i < propsMatches.length) {

                // default

                var name = propsMatches[i++][0];
                var type = propsMatches[i++][0];

                type = wgslTypeLib[type] || type;

                // precision

                if (i < propsMatches.length && propsMatches[i][0].startsWith('<') == true)
                    i++;

                // add input

                inputs.push(new NodeFunctionInput(type, name));

            }

            //

            var blockCode = source.substring(declaration[0].length);

            var name = declaration[1] !== undefined ? declaration[1] : '';
            var type = declaration[3] || 'void';

            return {
                type: type,
                inputs: inputs,
                name: name,
                inputsCode: inputsCode,
                blockCode: blockCode
            };

        } else {

            throw 'FunctionNode: Function is not a WGSL code.';

        }

    }

    public function new(source:String) {

        var parsed = parse(source);

        super(parsed.type, parsed.inputs, parsed.name);

        this.inputsCode = parsed.inputsCode;
        this.blockCode = parsed.blockCode;

    }

    public function getCode(name:String = this.name):String {

        var type = this.type != 'void' ? '-> ' + this.type : '';

        return 'fn ' + name + ' (' + this.inputsCode.trim() + ') ' + type + this.blockCode;

    }

}