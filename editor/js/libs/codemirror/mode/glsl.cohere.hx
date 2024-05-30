import CodeMirror.*;

@:noCompletion @:noCheck @:enum(noCompletion)
class Token {
    static var Null:Token;
    static var Comment:Token;
    static var String:Token;
    static var Atom:Token;
    static var Variable:Token;
    static var Number:Token;
    static var Operator:Token;
    static var Keyword:Token;
    static var Builtin:Token;
    static var Def:Token;
    static var Bracket:Token;
    static var Class:Token;
    static var Type:Token;
    static var Meta:Token;
}

class GLSLMode(CodeMirror.Mode) {
    var name:String;
    var keywords:Map<String, Dynamic>;
    var builtins:Map<String, Dynamic>;
    var blockKeywords:Map<String, Dynamic>;
    var atoms:Map<String, Dynamic>;
    var hooks:Map<String, Dynamic>;
    var multiLineStrings:Bool;
    var indentUnit:Int;
    var curPunc:String;

    function new(config:Dynamic, parserConfig:Dynamic) {
        name = "glsl";
        keywords = parserConfig.keywords || words(glslKeywords);
        builtins = parserConfig.builtins || words(glslBuiltins);
        blockKeywords = parserConfig.blockKeywords || words(["case", "do", "else", "for", "if", "switch", "while", "struct"]);
        atoms = parserConfig.atoms || words(["null"]);
        hooks = parserConfig.hooks || { };
        multiLineStrings = parserConfig.multiLineStrings;
        indentUnit = config.indentUnit;
        curPunc = "";
    }

    function tokenBase(stream:Dynamic, state:Dynamic) {
        var ch:String = stream.next();
        if (hooks.exists(ch)) {
            var result = hooks.get(ch)(stream, state);
            if (result != false) return result;
        }
        if (ch == '"' || ch == "'") {
            state.tokenize = tokenString(ch);
            return state.tokenize(stream, state);
        }
        if (["[", "]", "{", "}", "(", ")", ",", ":", "."].contains(ch)) {
            curPunc = ch;
            return "bracket";
        }
        if (ch.match("\\d")) {
            stream.eatWhile("\\w\\.");
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
            stream.eatWhile("[\\S]+");
            stream.eatWhile("[\\s]+");
            stream.eatWhile("[\\S]+");
            stream.eatWhile("[\\s]+");
            return "comment";
        }
        if (ch.match("[+\\-*&%=<>!?|/]")) {
            stream.eatWhile("[+\\-*&%=<>!?|/]");
            return "operator";
        }
        stream.eatWhile("[\\w\\$_]");
        var cur = stream.current();
        if (keywords.exists(cur)) {
            if (blockKeywords.exists(cur)) curPunc = "newstatement";
            return "keyword";
        }
        if (builtins.exists(cur)) {
            return "builtin";
        }
        if (atoms.exists(cur)) return "atom";
        return "word";
    }

    function tokenString(quote:String) {
        return function(stream:Dynamic, state:Dynamic) {
            var escaped = false, next:String, end = false;
            while ((next = stream.next()) != null) {
                if (next == quote && !escaped) {
                    end = true;
                    break;
                }
                escaped = !escaped && next == "\\";
            }
            if (end || !(escaped || multiLineStrings))
                state.tokenize = tokenBase;
            return "string";
        };
    }

    function tokenComment(stream:Dynamic, state:Dynamic) {
        var maybeEnd = false, ch:String;
        while (ch = stream.next()) {
            if (ch == "/" && maybeEnd) {
                state.tokenize = tokenBase;
                break;
            }
            maybeEnd = (ch == "*");
        }
        return "comment";
    }

    class Context {
        var indented:Int;
        var column:Int;
        var `type`:String;
        var align:Bool;
        var prev:Context;

        function new(indented:Int, column:Int, `type`:String, align:Bool, prev:Context) {
            this.indented = indented;
            this.column = column;
            this.type = `type`;
            this.align = align;
            this.prev = prev;
        }
    }

    function pushContext(state:Dynamic, col:Int, `type`:String) {
        return state.context = new Context(state.indented, col, `type`, false, state.context);
    }

    function popContext(state:Dynamic) {
        var t = state.context.type;
        if (["", ")","]","}"].contains(t))
            state.indented = state.context.indented;
        return state.context = state.context.prev;
    }

    static function get(CodeMirror:Dynamic) {
        return {
            startState: function(basecolumn:Int) {
                return {
                    tokenize: null,
                    context: new Context((basecolumn || 0) - indentUnit, 0, "top", false),
                    indented: 0,
                    startOfLine: true
                };
            },

            token: function(stream:Dynamic, state:Dynamic) {
                var ctx = state.context;
                if (stream.sol()) {
                    if (ctx.align == null) ctx.align = false;
                    state.indented = stream.indentation();
                    state.startOfLine = true;
                }
                if (stream.eatSpace()) return null;
                curPunc = "";
                var style = (state.tokenize || tokenBase)(stream, state);
                if (["comment", "meta"].contains(style)) return style;
                if (ctx.align == null) ctx.align = true;

                if ([";", ":"].contains(curPunc) && ctx.type == "statement") popContext(state);
                else if (curPunc == "{") pushContext(state, stream.column(), "}");
                else if (curPunc == "[") pushContext(state, stream.column(), "]");
                else if (curPunc == "(") pushContext(state, stream.column(), ")");
                else if (curPunc == "}") {
                    while (ctx.type == "statement") ctx = popContext(state);
                    if (ctx.type == "}") ctx = popContext(state);
                    while (ctx.type == "statement") ctx = popContext(state);
                }
                else if (curPunc == ctx.type) popContext(state);
                else if (["}", "top", "statement"].contains(ctx.type) && curPunc == "newstatement")
                    pushContext(state, stream.column(), "statement");
                state.startOfLine = false;
                return style;
            },

            indent: function(state:Dynamic, textAfter:String) {
                if (["tokenBase", null].contains(state.tokenize)) {
                    var firstChar = textAfter.charAt(0);
                    var ctx = state.context;
                    var closing = firstChar == ctx.type;
                    if (ctx.type == "statement") return ctx.indented + (firstChar == "{" ? 0 : indentUnit);
                    else if (ctx.align) return ctx.column + (closing ? 0 : 1);
                    else return ctx.indented + (closing ? 0 : indentUnit);
                }
                return 0;
            },

            electricChars: "{}",

            name: name,
            keywords: keywords,
            builtins: builtins,
            blockKeywords: blockKeywords,
            atoms: atoms,
            hooks: hooks
        };
    }
}

function words(str:String) {
    var obj = Map<String, Dynamic>();
    var words = str.split(" ");
    for (word in words) {
        obj.set(word, true);
    }
    return obj;
}

var glslKeywords = "attribute const uniform varying break continue do for while if else in out inout float int void bool true false lowp mediump highp precision invariant discard return mat2 mat3 mat4 vec2 vec3 vec4 ivec2 ivec3 ivec4 bvec2 bvec3 bvec4 sampler2D samplerCube struct gl_FragCoord gl_FragColor gl_Position";
var glslBuiltins = "radians degrees sin cos tan asin acos atan pow exp log exp2 log2 sqrt inversesqrt abs sign floor ceil fract mod min max clamp mix step smoothstep length distance dot cross normalize faceforward reflect refract matrixCompMult lessThan lessThanEqual greaterThan greaterThanEqual equal notEqual any all not dFdx dFdy fwidth texture2D texture2DProj texture2DLod texture2DProjLod textureCube textureCubeLod require export";

function cppHook(stream:Dynamic, state:Dynamic) {
    if (!state.startOfLine) return false;
    stream.skipToEnd();
    return "meta";
}

class Main {
    static function main() {
        CodeMirror.defineMIME("text/x-glsl", {
            name: "glsl",
            keywords: words(glslKeywords),
            builtins: words(glslBuiltins),
            blockKeywords: words(["case", "do", "else", "for", "if", "switch", "while", "struct"]),
            atoms: words(["null"]),
            hooks: {"#": cppHook}
        });
    }
}