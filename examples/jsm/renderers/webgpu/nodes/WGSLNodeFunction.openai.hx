package three.js.examples.jsw.renderers.webgpu.nodes;

import three.js.nodes.core.NodeFunction;
import three.js.nodes.core.NodeFunctionInput;

class WGSLNodeFunction extends NodeFunction {
  public var inputsCode:String;
  public var blockCode:String;

  static var declarationRegexp = ~/^[fn]*\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)\s*[\-\>]*\s*([a-z_0-9]+)?/i;
  static var propertiesRegexp = ~/[a-z_0-9]+|<(.*?)>+$/ig;

  static var wgslTypeLib = [
    'f32' => 'float'
  ];

  static function parse(source:String):{
    type:String,
    inputs:Array<NodeFunctionInput>,
    name:String,
    inputsCode:String,
    blockCode:String
  } {
    source = source.trim();

    var declaration = declarationRegexp.match(source);

    if (declaration != null && declaration.length == 4) {
      // tokenizer

      var inputsCode = declaration[2];
      var propsMatches = [];

      var nameMatch = null;

      while ((nameMatch = propertiesRegexp.exec(inputsCode)) != null) {
        propsMatches.push(nameMatch);
      }

      // parser

      var inputs = [];

      var i = 0;

      while (i < propsMatches.length) {
        // default

        var name = propsMatches[i++][0];
        var type = propsMatches[i++][0];

        type = wgslTypeLib[type] != null ? wgslTypeLib[type] : type;

        // precision

        if (i < propsMatches.length && propsMatches[i][0].startsWith('<')) {
          i++;
        }

        // add input

        inputs.push(new NodeFunctionInput(type, name));
      }

      //

      var blockCode = source.substring(declaration[0].length);

      var name = declaration[1] != null ? declaration[1] : '';
      var type = declaration[3] != null ? declaration[3] : 'void';

      return {
        type: type,
        inputs: inputs,
        name: name,
        inputsCode: inputsCode,
        blockCode: blockCode
      };
    } else {
      throw new Error('FunctionNode: Function is not a WGSL code.');
    }
  }

  public function new(source:String) {
    var data = parse(source);

    super(data.type, data.inputs, data.name);

    this.inputsCode = data.inputsCode;
    this.blockCode = data.blockCode;
  }

  public function getCode(?name:String):String {
    var type = this.type != 'void' ? '-> ' + this.type : '';

    return 'fn ' + (name != null ? name : this.name) + ' ( ' + this.inputsCode.trim() + ' ) ' + type + this.blockCode;
  }
}