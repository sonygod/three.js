package three.js.editor.js.libs.codemirror.mode.glsl;

// License information and copyright notices have been removed for brevity

class GLSLMode {
  public static function defineMode(config:Dynamic, parserConfig:Dynamic) {
    var indentUnit:Int = config.indentUnit;
    var keywords:Dynamic = parserConfig.keywords != null ? parserConfig.keywords : words(glslKeywords);
    var builtins:Dynamic = parserConfig.builtins != null ? parserConfig.builtins : words(glslBuiltins);
    var blockKeywords:Dynamic = parserConfig.blockKeywords != null ? parserConfig.blockKeywords : words("case do else for if switch while struct");
    var atoms:Dynamic = parserConfig.atoms != null ? parserConfig.atoms : words("null");
    var hooks:Dynamic = parserConfig.hooks != null ? parserConfig.hooks : {};
    var multiLineStrings:Bool = parserConfig.multiLineStrings;

    var isOperatorChar:EReg = ~/[+\-*&%=<>!?|\/]/;

    var curPunc:String = null;

    function tokenBase(stream:Stream, state:Dynamic) {
      var ch:String = stream.next();
      if (hooks[ch] != null) {
        var result:Dynamic = hooks[ch](stream, state);
        if (result != false) return result;
      }
      if (ch == '"' || ch == "'") {
        state.tokenize = tokenString(ch);
        return state.tokenize(stream, state);
      }
      if (~/[[\]{}\(\),;\:.]/.test(ch)) {
        curPunc = ch;
        return "bracket";
      }
      if (~/\d/.test(ch)) {
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
      if (isOperatorChar.test(ch)) {
        stream.eatWhile(isOperatorChar);
        return "operator";
      }
      stream.eatWhile ~/[\w\$_]/;
      var cur:String = stream.current();
      if (keywords[cur] != null) {
        if (blockKeywords[cur] != null) curPunc = "newstatement";
        return "keyword";
      }
      if (builtins[cur] != null) {
        return "builtin";
      }
      if (atoms[cur] != null) return "atom";
      return "word";
    }

    function tokenString(quote:String):Stream->State->String {
      return function(stream:Stream, state:Dynamic) {
        var escaped:Bool = false;
        var next:String;
        var end:Bool = false;
        while ((next = stream.next()) != null) {
          if (next == quote && !escaped) {
            end = true;
            break;
          }
          escaped = !escaped && next == "\\";
        }
        if (end || !(escaped || multiLineStrings)) {
          state.tokenize = tokenBase;
        }
        return "string";
      };
    }

    function tokenComment(stream:Stream, state:Dynamic) {
      var maybeEnd:Bool = false;
      var ch:String;
      while ((ch = stream.next()) != null) {
        if (ch == "/" && maybeEnd) {
          state.tokenize = tokenBase;
          break;
        }
        maybeEnd = (ch == "*");
      }
      return "comment";
    }

    function Context(indented:Int, column:Int, type:String, align:Bool, prev:Context) {
      this.indented = indented;
      this.column = column;
      this.type = type;
      this.align = align;
      this.prev = prev;
    }

    function pushContext(state:Dynamic, col:Int, type:String) {
      return state.context = new Context(state.indented, col, type, null, state.context);
    }

    function popContext(state:Dynamic) {
      var t:String = state.context.type;
      if (t == ")" || t == "]" || t == "}")
        state.indented = state.context.indented;
      return state.context = state.context.prev;
    }

    // Interface

    return {
      startState: function(basecolumn:Int) {
        return {
          tokenize: null,
          context: new Context((basecolumn != 0 ? basecolumn : 0) - indentUnit, 0, "top", false, null),
          indented: 0,
          startOfLine: true
        };
      },

      token: function(stream:Stream, state:Dynamic) {
        var ctx:Context = state.context;
        if (stream.sol()) {
          if (ctx.align == null) ctx.align = false;
          state.indented = stream.indentation();
          state.startOfLine = true;
        }
        if (stream.eatSpace()) return null;
        curPunc = null;
        var style:String = (state.tokenize != null ? state.tokenize : tokenBase)(stream, state);
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
      },

      indent: function(state:Dynamic, textAfter:String) {
        if (state.tokenize != tokenBase && state.tokenize != null) return 0;
        var firstChar:String = textAfter.charAt(0);
        var ctx:Context = state.context;
        var closing:Bool = firstChar == ctx.type;
        if (ctx.type == "statement") return ctx.indented + (firstChar == "{" ? 0 : indentUnit);
        else if (ctx.align) return ctx.column + (closing ? 0 : 1);
        else return ctx.indented + (closing ? 0 : indentUnit);
      },

      electricChars: "{}"
    };
  }

  public static function words(str:String):Dynamic {
    var obj:Dynamic = {};
    var words:Array<String> = str.split(" ");
    for (i in 0...words.length) obj[words[i]] = true;
    return obj;
  }

  public static var glslKeywords:String = "attribute const uniform varying break continue " +
    "do for while if else in out inout float int void bool true false " +
    "lowp mediump highp precision invariant discard return mat2 mat3 " +
    "mat4 vec2 vec3 vec4 ivec2 ivec3 ivec4 bvec2 bvec3 bvec4 sampler2D " +
    "samplerCube struct gl_FragCoord gl_FragColor gl_Position";

  public static var glslBuiltins:String = "radians degrees sin cos tan asin acos atan pow " +
    "exp log exp2 log2 sqrt inversesqrt abs sign floor ceil fract mod " +
    "min max clamp mix step smoothstep length distance dot cross " +
    "normalize faceforward reflect refract matrixCompMult lessThan " +
    "lessThanEqual greaterThan greaterThanEqual equal notEqual any all " +
    "not dFdx dFdy fwidth texture2D texture2DProj texture2DLod " +
    "texture2DProjLod textureCube textureCubeLod require export";

  public static function cppHook(stream:Stream, state:Dynamic) {
    if (!state.startOfLine) return false;
    stream.skipToEnd();
    return "meta";
  }

  public static function defineMIME() {
    CodeMirror.defineMIME("text/x-glsl", {
      name: "glsl",
      keywords: words(glslKeywords),
      builtins: words(glslBuiltins),
      blockKeywords: words("case do else for if switch while struct"),
      atoms: words("null"),
      hooks: {"#": cppHook}
    });
  }
}