import NodeFunction from "../core/NodeFunction";
import NodeFunctionInput from "../core/NodeFunctionInput";

class GLSLNodeFunction extends NodeFunction {
  var inputsCode:String;
  var blockCode:String;
  var headerCode:String;

  public function new(source:String) {
    var {type, inputs, name, presicion, inputsCode, blockCode, headerCode} = parse(source);
    super(type, inputs, name, presicion);
    this.inputsCode = inputsCode;
    this.blockCode = blockCode;
    this.headerCode = headerCode;
  }

  public function getCode(name:String = this.name):String {
    var code:String;
    var blockCode = this.blockCode;

    if (blockCode != "") {
      var {type, inputsCode, headerCode, presicion} = this;
      var declarationCode = "${type} ${name} (${inputsCode.trim()})";
      if (presicion != "") {
        declarationCode = "${presicion} ${declarationCode}";
      }

      code = headerCode + declarationCode + blockCode;
    } else {
      // interface function
      code = "";
    }

    return code;
  }
}

var declarationRegexp = ~/^\s*(highp|mediump|lowp)?\s*([a-z_0-9]+)\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)/i;
var propertiesRegexp = /[a-z_0-9]+/ig;
var pragmaMain = "#pragma main";

function parse(source:String):{type:String, inputs:Array<NodeFunctionInput>, name:String, presicion:String, inputsCode:String, blockCode:String, headerCode:String} {
  source = source.trim();
  var pragmaMainIndex = source.indexOf(pragmaMain);
  var mainCode = pragmaMainIndex != -1 ? source.slice(pragmaMainIndex + pragmaMain.length) : source;
  var declaration = mainCode.match(declarationRegexp);

  if (declaration != null && declaration.length == 5) {
    // tokenizer
    var inputsCode = declaration[4];
    var propsMatches:Array<String> = [];
    var nameMatch:Match = null;
    while ((nameMatch = propertiesRegexp.exec(inputsCode)) != null) {
      propsMatches.push(nameMatch[0]);
    }

    // parser
    var inputs:Array<NodeFunctionInput> = [];
    var i = 0;
    while (i < propsMatches.length) {
      var isConst = propsMatches[i] == "const";
      if (isConst) {
        i++;
      }

      var qualifier:String = propsMatches[i];
      if (qualifier == "in" || qualifier == "out" || qualifier == "inout") {
        i++;
      } else {
        qualifier = "";
      }

      var type = propsMatches[i++];
      var count:Int = Std.parseInt(propsMatches[i]);
      if (!Math.isNaN(count)) i++;
      else count = null;
      var name = propsMatches[i++];

      inputs.push(new NodeFunctionInput(type, name, count, qualifier, isConst));
    }

    //
    var blockCode = mainCode.substring(declaration[0].length);
    var name = declaration[3] != null ? declaration[3] : "";
    var type = declaration[2];
    var presicion = declaration[1] != null ? declaration[1] : "";
    var headerCode = pragmaMainIndex != -1 ? source.slice(0, pragmaMainIndex) : "";
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
    throw new Error("FunctionNode: Function is not a GLSL code.");
  }
}

export default GLSLNodeFunction;