package three.js_examples_jsm_nodes_parsers;

import haxe.regex.Regex;
import haxe.ds.StringMap;

class GLSLNodeFunction extends NodeFunction {
    public var inputsCode:String;
    public var blockCode:String;
    public var headerCode:String;

    public function new(source:String) {
        var parsed = parse(source);
        super(parsed.type, parsed.inputs, parsed.name, parsed.presicion);
        this.inputsCode = parsed.inputsCode;
        this.blockCode = parsed.blockCode;
        this.headerCode = parsed.headerCode;
    }

    public function getCode(name:String = null):String {
        if (name == null) name = this.name;
        var blockCode = this.blockCode;
        if (blockCode != '') {
            var code = this.headerCode;
            if (this.presicion != '') {
                code += this.presicion + ' ';
            }
            code += this.type + ' ' + name + ' (' + this.inputsCode.trim() + ') ' + blockCode;
            return code;
        } else {
            return ''; // interface function
        }
    }

    static function parse(source:String):{ type:String, inputs:Array<NodeFunctionInput>, name:String, presicion:String, inputsCode:String, blockCode:String, headerCode:String } {
        source = StringTools.trim(source);
        var pragmaMainIndex = source.indexOf('#pragma main');
        var mainCode = if (pragmaMainIndex != -1) source.substring(pragmaMainIndex + 7) else source;
        var declaration = Regex.match(mainCode, ~/^\s*(highp|mediump|lowp)?\s*([a-z_0-9]+)\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)/i);
        if (declaration != null && declaration.length == 5) {
            var inputsCode = declaration[4];
            var propsMatches = ~/[a-z_0-9]+/ig;
            var propsMatchesArray:Array<RegexMatch> = [];
            var nameMatch:RegexMatch;
            while ((nameMatch = propsMatches.exec(inputsCode)) != null) {
                propsMatchesArray.push(nameMatch);
            }
            var inputs:Array<NodeFunctionInput> = [];
            for (i in 0...propsMatchesArray.length) {
                var isConst = propsMatchesArray[i][0] == 'const';
                if (isConst) i++;
                var qualifier = propsMatchesArray[i][0];
                if (qualifier == 'in' || qualifier == 'out' || qualifier == 'inout') {
                    i++;
                    qualifier = '';
                }
                var type = propsMatchesArray[i++][0];
                var count:Int = parseInt(propsMatchesArray[i++][0]);
                if (Math.isNaN(count)) {
                    count = null;
                }
                var name = propsMatchesArray[i++][0];
                inputs.push(new NodeFunctionInput(type, name, count, qualifier, isConst));
            }
            var blockCode = mainCode.substring(declaration[0].length);
            var name = if (declaration[3] != null) declaration[3] else '';
            var type = declaration[2];
            var presicion = if (declaration[1] != null) declaration[1] else '';
            var headerCode = if (pragmaMainIndex != -1) source.substring(0, pragmaMainIndex) else '';
            return { type: type, inputs: inputs, name: name, presicion: presicion, inputsCode: inputsCode, blockCode: blockCode, headerCode: headerCode };
        } else {
            throw new Error('FunctionNode: Function is not a GLSL code.');
        }
    }
}