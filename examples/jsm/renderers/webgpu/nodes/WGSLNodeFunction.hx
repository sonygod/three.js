Here is the converted Haxe code:
```
package three.js.examples.jsm.renderers.webgpu.nodes;

import three.js.nodes.core.NodeFunction;
import three.js.nodes.core.NodeFunctionInput;

class WGSLNodeFunction extends NodeFunction {
    public var inputsCode:String;
    public var blockCode:String;

    static var declarationRegexp:EReg = ~/^[fn]*\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)\s*[\-\>]*\s*([a-z_0-9]+)?/i;
    static var propertiesRegexp:EReg = ~/[a-z_0-9]+|<(.*?)>+/ig;

    static var wgslTypeLib:Map<String, String> = [
        "f32" => "float"
    ];

    static function parse(source:String):{type:String, inputs:Array<NodeFunctionInput>, name:String, inputsCode:String, blockCode:String} {
        source = StringTools.trim(source);

        var declaration:Array<String> = declarationRegexp.match(source);
        if (declaration != null && declaration.length == 4) {
            var inputsCode:String = declaration[2];
            var propsMatches:Array<Array<String>> = [];

            var nameMatch:Array<String>;
            while ((nameMatch = propertiesRegexp.exec(inputsCode)) != null) {
                propsMatches.push(nameMatch);
            }

            var inputs:Array<NodeFunctionInput> = [];
            for (i in 0...propsMatches.length) {
                var name:String = propsMatches[i][0];
                var type:String = propsMatches[i + 1][0];
                type = wgslTypeLib[type] != null ? wgslTypeLib[type] : type;

                if (i < propsMatches.length - 1 && propsMatches[i + 1][0].startsWith("<")) {
                    i++;
                }

                inputs.push(new NodeFunctionInput(type, name));
            }

            var blockCode:String = source.substring(declaration[0].length);
            var name:String = declaration[1] != null ? declaration[1] : '';
            var type:String = declaration[3] != null ? declaration[3] : 'void';

            return {type: type, inputs: inputs, name: name, inputsCode: inputsCode, blockCode: blockCode};
        } else {
            throw new Error('FunctionNode: Function is not a WGSL code.');
        }
    }

    public function new(source:String) {
        var parsed:Object = parse(source);
        super(parsed.type, parsed.inputs, parsed.name);
        this.inputsCode = parsed.inputsCode;
        this.blockCode = parsed.blockCode;
    }

    public function getCode(?name:String):String {
        var type:String = this.type != 'void' ? '-> ' + this.type : '';
        return 'fn ' + (name != null ? name : this.name) + ' (' + this.inputsCode.trim() + ') ' + type + this.blockCode;
    }
}
```
Note that I've used the Haxe `EReg` class to replace the JavaScript regexps, and `Map<String, String>` to replace the JavaScript object `wgslTypeLib`. I've also replaced the JavaScript `trim()` method with the Haxe `StringTools.trim()` function.