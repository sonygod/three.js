package three.js.editor.js.libs.codemirror.mode;

import haxe.Exception;

class GLSLMode {
  static var keywords:Array<String> = [
    "attribute", "const", "uniform", "varying", "break", "continue", "do", "for", "while", "if", "else", "in", "out", "inout", "float", "int", "void", "bool", "true", "false",
    "lowp", "mediump", "highp", "precision", "invariant", "discard", "return", "mat2", "mat3", "mat4", "vec2", "vec3", "vec4", "ivec2", "ivec3", "ivec4", "bvec2", "bvec3", "bvec4", "sampler2D", "samplerCube", "struct", "gl_FragCoord", "gl_FragColor", "gl_Position"
  ];

  static var builtins:Array<String> = [
    "radians", "degrees", "sin", "cos", "tan", "asin", "acos", "atan", "pow", "exp", "exp2", "log", "log2", "sqrt", "inversesqrt", "abs", "sign", "floor", "ceil", "fract", "mod", "min", "max", "clamp", "mix", "step", "smoothstep", "length", "distance", "dot", "cross", "normalize", "faceforward", "reflect", "refract", "matrixCompMult", "lessThan", "lessThanEqual", "greaterThan", "greaterThanEqual", "equal", "notEqual", "any", "all", "not", "dFdx", "dFdy", "fwidth", "texture2D", "texture2DProj", "texture2DLod", "texture2DProjLod", "textureCube", "textureCubeLod", "require", "export"
  ];

  static var blockKeywords:Array<String> = ["case", "do", "else", "for", "if", "switch", "while", "struct"];
  static var atoms:Array<String> = ["null"];

  static var hooks:Map<String, Void->Void> = ["#" => cppHook];

  static function tokenBase(stream:TokenStream, state:TokenState):String {
    var ch = stream.next();
    if (hooks.exists(ch)) {
      var result = hooks[ch](stream, state);
      if (result != false) return result;
    }
    if (ch == '"' || ch == "'") {
      state.tokenize = tokenString(ch);
      return state.tokenize(stream, state);
    }
    if (~/\[{}();:\.]/.match(ch)) {
      curPunc = ch;
      return "bracket";
    }
    if (~/\d/.match(ch)) {
      stream.eatWhile ~/[\w\.]/;
      return "number";
    }
    if (ch == "/") {
      if (stream.eat("*")) {
        state.tokenize = tokenComment;
        return tokenComment(stream, state);
      }
      if (stream.eat("/")) {
        stream.skipToEnd();
        return "comment";
      }
    }
    if (ch == "#") {
      stream.eatWhile ~/[\S]+/;
      stream.eatWhile ~/[\s]+/;
      stream.eatWhile ~/[\S]+/;
      stream.eatWhile ~/[\s]+/;
      return "comment";
    }
    if (~/[+\-*&%=<>!?|\/]/.match(ch)) {
      stream.eatWhile ~/[+\-*&%=<>!?|\/]/;
      return "operator";
    }
    stream.eatWhile ~/[\w\$_]/;
    var cur = stream.current();
    if (keywords.indexOf(cur) != -1) {
      if (blockKeywords.indexOf(cur) != -1) curPunc = "newstatement";
      return "keyword";
    }
    if (builtins.indexOf(cur) != -1) {
      return "builtin";
    }
    if (atoms.indexOf(cur) != -1) return "atom";
    return "word";
  }

  static function tokenString(quote:String):Void->Void {
    return function(stream:TokenStream, state:TokenState):String {
      var escaped = false, next, end = false;
      while ((next = stream.next()) != null) {
        if (next == quote && !escaped) {end = true; break;}
        escaped = !escaped && next == "\\";
      }
      if (end || !(escaped || multiLineStrings))
        state.tokenize = tokenBase;
      return "string";
    };
  }

  static function tokenComment(stream:TokenStream, state:TokenState):String {
    var maybeEnd = false, ch;
    while (ch = stream.next()) {
      if (ch == "/" && maybeEnd) {
        state.tokenize = tokenBase;
        break;
      }
      maybeEnd = (ch == "*");
    }
    return "comment";
  }

  static function Context(indented:Int, column:Int, type:String, align:Bool, prev:Context):Context {
    this.indented = indented;
    this.column = column;
    this.type = type;
    this.align = align;
    this.prev = prev;
  }

  static function pushContext(state:TokenState, col:Int, type:String):Context {
    return state.context = new Context(state.indented, col, type, null, state.context);
  }

  static function popContext(state:TokenState):Context {
    var t = state.context.type;
    if (t == ")" || t == "]" || t == "}")
      state.indented = state.context.indented;
    return state.context = state.context.prev;
  }

  static function startState(basecolumn:Int):TokenState {
    return {
      tokenize: null,
      context: new Context((basecolumn || 0) - indentUnit, 0, "top", false),
      indented: 0,
      startOfLine: true
    };
  }

  static function token(stream:TokenStream, state:TokenState):String {
    var ctx = state.context;
    if (stream.sol()) {
      if (ctx.align == null) ctx.align = false;
      state.indented = stream.indentation();
      state.startOfLine = true;
    }
    if (stream.eatSpace()) return null;
    curPunc = null;
    var style = (state.tokenize || tokenBase)(stream, state);
    if (style == "comment" || style == "meta") return style;
    if (ctx.align == null) ctx.align = true;

    if ((curPunc == ";" || curPunc == ":") && ctx.type == "statement") popContext(state);
    else if (curPunc == "{") pushContext(state, stream.column(), "}");
    else if (curPunc == "[") pushContext(state, stream.column(), "]");
    else if (curPunc == "(") pushContext(state, stream.column(), ")");
    else if (curPunc == "}") {
      while (ctx.type == "statement") ctx = popContext(state);
      if (ctx.type == "}") ctx = popContext(state);
      while (ctx.type == "statement") ctx = popContext(state);
    }
    else if (curPunc == ctx.type) popContext(state);
    else if (ctx.type == "}" || ctx.type == "top" || (ctx.type == "statement" && curPunc == "newstatement"))
      pushContext(state, stream.column(), "statement");
    state.startOfLine = false;
    return style;
  }

  static function indent(state:TokenState, textAfter:String):Int {
    if (state.tokenize != tokenBase && state.tokenize != null) return 0;
    var firstChar = textAfter.charAt(0), ctx = state.context, closing = firstChar == ctx.type;
    if (ctx.type == "statement") return ctx.indented + (firstChar == "{" ? 0 : indentUnit);
    else if (ctx.align) return ctx.column + (closing ? 0 : 1);
    else return ctx.indented + (closing ? 0 : indentUnit);
  }

  static function cppHook(stream:TokenStream, state:TokenState):String {
    if (!state.startOfLine) return false;
    stream.skipToEnd();
    return "meta";
  }

  static function defineMode():Void {
    CodeMirror.defineMode("glsl", function(config, parserConfig) {
      var indentUnit = config.indentUnit,
          keywords = parserConfig.keywords || words(glslKeywords),
          builtins = parserConfig.builtins || words(glslBuiltins),
          blockKeywords = parserConfig.blockKeywords || words("case do else for if switch while struct"),
          atoms = parserConfig.atoms || words("null"),
          hooks = parserConfig.hooks || {};
      hooks["#"] = cppHook;
      return {
        startState: startState,
        token: token,
        indent: indent,
        electricChars: "{}"
      };
    });
  }

  static function defineMIME():Void {
    CodeMirror.defineMIME("text/x-glsl", {
      name: "glsl",
      keywords: words(glslKeywords),
      builtins: words(glslBuiltins),
      blockKeywords: words("case do else for if switch while struct"),
      atoms: words("null"),
      hooks: {"#": cppHook}
    });
  }

  static function main():Void {
    defineMode();
    defineMIME();
  }

  static function words(str:String):Map<String, Bool> {
    var obj = new Map<String, Bool>();
    var words = str.split(" ");
    for (i in 0...words.length) obj[words[i]] = true;
    return obj;
  }
}