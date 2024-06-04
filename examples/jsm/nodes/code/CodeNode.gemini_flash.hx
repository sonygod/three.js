import Node from "../core/Node";
import ShaderNode from "../shadernode/ShaderNode";

class CodeNode extends Node {
  public var isCodeNode:Bool = true;
  public var code:String;
  public var language:String;
  public var includes:Array<Dynamic>;

  public function new(code:String = "", includes:Array<Dynamic> = [], language:String = "") {
    super("code");
    this.code = code;
    this.language = language;
    this.includes = includes;
  }

  public function isGlobal():Bool {
    return true;
  }

  public function setIncludes(includes:Array<Dynamic>):CodeNode {
    this.includes = includes;
    return this;
  }

  public function getIncludes(builder:Dynamic):Array<Dynamic> {
    return this.includes;
  }

  public function generate(builder:Dynamic):String {
    var includes = this.getIncludes(builder);
    for (include in includes) {
      include.build(builder);
    }

    var nodeCode = builder.getCodeFromNode(this, this.getNodeType(builder));
    nodeCode.code = this.code;

    return nodeCode.code;
  }

  public function serialize(data:Dynamic) {
    super.serialize(data);
    data.code = this.code;
    data.language = this.language;
  }

  public function deserialize(data:Dynamic) {
    super.deserialize(data);
    this.code = data.code;
    this.language = data.language;
  }
}

class CodeNodeProxy extends ShaderNode {
  public function new() {
    super();
  }
  public function create(code:String, includes:Array<Dynamic>, language:String):CodeNode {
    return new CodeNode(code, includes, language);
  }
}

var code:CodeNodeProxy = new CodeNodeProxy();

function js(src:String, includes:Array<Dynamic>):CodeNode {
  return code.create(src, includes, "js");
}

function wgsl(src:String, includes:Array<Dynamic>):CodeNode {
  return code.create(src, includes, "wgsl");
}

function glsl(src:String, includes:Array<Dynamic>):CodeNode {
  return code.create(src, includes, "glsl");
}

Node.addNodeClass("CodeNode", CodeNode);

export { CodeNode, code, js, wgsl, glsl };