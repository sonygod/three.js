import haxe.Serializer;
import haxe.Unserializer;
import js.Browser;
import js.html.Document;
import js.html.Element;
import js.html.HTMLElement;
import js.html.HTMLCollection;
import js.html.HTMLDocument;
import js.html.HTMLFormElement;
import js.html.HTMLImageElement;
import js.html.HTMLInputElement;
import js.html.HTMLScriptElement;
import js.html.HTMLStyleElement;
import js.html.HTMLTextAreaElement;
import js.html.Window;
import js.lib.Document;
import js.node.ArrayBuffer;
import js.node.Buffer;
import js.node.ChildProcess;
import js.node.Console;
import js.node.Error;
import js.node.EventEmitter;
import js.node.Fs;
import js.node.Global;
import js.node.Http;
import js.node.Https;
import js.node.Module;
import js.node.Net;
import js.node.Node;
import js.node.Os;
import js.node.Path;
import js.node.Process;
import js.node.Querystring;
import js.node.Readline;
import js.node.Require;
import js.node.Stream;
import js.node.Timers;
import js.node.Url;
import js.node.Util;
import js.node.Vm;
import js.node.Zlib;
import js.sys.ArrayBuffer;
import js.sys.Date;
import js.sys.Dynamic;
import js.sys.Error;
import js.sys.Function;
import js.sys.Math;
import js.sys.Reflect;
import js.sys.RegExp;
import js.sys.StringBuf;
import js.sys.Sys;
import js.sys.TypedArray;
import js.sys.Utf8;
import js.sys.VList;
import js.sys.Weak;
import js.Browser;
import js.html;
import js.node;
import js.sys;
import js.Array;
import js.Bool;
import js.Class;
import js.Date;
import js.Dynamic;
import js.Error;
import js.Function;
import js.Int;
import js.Iterator;
import js.Lib;
import js.Map;
import js.Math;
import js.Null;
import js.Reflect;
import js.Regex;
import js.String;
import js.Sys;
import js.Type;
import js.UInt;
import js.VArray;
import js.Weak;
import js.Xml;
import js.io;
import js.node;
import js.sys;
import js.ui;
import js.ut;
import js.Browser;
import js.html;
import js.node;
import js.sys;
import js.ui;
import js.ut;
class CodeMirror {
	public function new(config:Dynamic, parserConfig:Dynamic):Void;
	public function defineMode(mime:String, mode:Dynamic):Void;
	public function startState(basecolumn:Int):Dynamic;
	public function token(stream:Dynamic, state:Dynamic):Dynamic;
	public function indent(state:Dynamic, textAfter:String):Int;
	public function electricInput(text:String):Bool;
	public function blockCommentStart:String;
	public function blockCommentEnd:String;
	public function blockCommentContinue:String;
	public function lineComment:String;
	public function fold(text:String, start:Int):Dynamic;
	public function closeBrackets:String;
	public function helperType:String;
	public function jsonldMode:Bool;
	public function jsonMode:Bool;
	public function expressionAllowed(stream:Dynamic, state:Dynamic, backUp:Int):Bool;
	public function skipExpression(state:Dynamic):Void;
}
class Main {
	public static function main():Void {
		var mod:Dynamic = function(CodeMirror) {
			"use strict";
			CodeMirror.defineMode("javascript", function(config, parserConfig) {
				var indentUnit = config.indentUnit;
				var statementIndent = parserConfig.statementIndent;
				var jsonldMode = parserConfig.jsonld;
				var jsonMode = parserConfig.json || jsonldMode;
				var trackScope = parserConfig.trackScope !== false
				var isTS = parserConfig.typescript;
				var wordRE = parserConfig.wordCharacters || /[\w$\xa1-\uffff]/;
				var keywords = function() {
					function kw(type) {return {type: type, style: "keyword"};}
					var A = kw("keyword a"), B = kw("keyword b"), C = kw("keyword c"), D = kw("keyword d");
					var operator = kw("operator"), atom = {type: "atom", style: "atom"};
					return {
						"if": kw("if"), "while": A, "with": A, "else": B, "do": B, "try": B, "finally": B,
						"return": D, "break": D, "continue": D, "new": kw("new"), "delete": C, "void": C, "throw": C,
						"debugger": kw("debugger"), "var": kw("var"), "const": kw("var"), "let": kw("var"),
						"function": kw("function"), "catch": kw("catch"),
						"for": kw("for"), "switch": kw("switch"), "case": kw("case"), "default": kw("default"),
						"in": operator, "typeof": operator, "instanceof": operator,
						"true": atom, "false": atom, "null": atom, "undefined": atom, "NaN": atom, "Infinity": atom,
						"this": kw("this"), "class": kw("class"), "super": kw("atom"),
						"yield": C, "export": kw("export"), "import": kw("import"), "extends": C,
						"await": C
					};
				}();
				var isOperatorChar = /[+\-*&%=<>!?|~^@]/;
				var isJsonldKeyword = /^@(context|id|value|language|type|container|list|set|reverse|index|base|vocab|graph)"/;
				function readRegexp(stream) {
					var escaped = false, next, inSet = false;
					while ((next = stream.next()) != null) {
						if (!escaped) {
							if (next == "/" && !inSet) return;
							if (next == "[") inSet = true;
							else if (inSet && next == "]") inSet = false;
						}
						escaped = !escaped && next == "\\";
					}
				}
				var type, content;
				function ret(tp, style, cont) {
					type = tp; content = cont;
					return style;
				}
				function tokenBase(stream, state) {
					var ch = stream.next();
					if (ch == '"' || ch == "'") {
						state.tokenize = tokenString(ch);
						return state.tokenize(stream, state);
					} else if (ch == "." && stream.match(/^\d[\d_]*(?:[eE][+\-]?[\d_]+)?/)) {
						return ret("number", "number");
					} else if (ch == "." && stream.match("..")) {
						return ret("spread", "meta");
					} else if (/[\[\]{}\(\),;\:\.]/.test(ch)) {
						return ret(ch);
					} else if (ch == "=" && stream.eat(">")) {
						return ret("=>", "operator");
					} else if (ch == "0" && stream.match(/^(?:x[\dA-Fa-f_]+|o[0-7_]+|b[01_]+)n?/)) {
						return ret("number", "number");
					} else if (/\d/.test(ch)) {
						stream.match(/^[\d_]*(?:n|(?:\.[\d_]*)?(?:[eE][+\-]?[\d_]+)?)?/);
						return ret("number", "number");
					} else if (ch == "/") {
						if (stream.eat("*")) {
							state.tokenize = tokenComment;
							return tokenComment(stream, state);
						} else if (stream.eat("/")) {
							stream.skipToEnd();
							return ret("comment", "comment");
						} else if (expressionAllowed(stream, state, 1)) {
							readRegexp(stream);
							stream.match(/^\b(([gimyus])(?![gimyus]*\2))+\b/);
							return ret("regexp", "string-2");
						} else {
							stream.eat("=");
							return ret("operator", "operator", stream.current());
						}
					} else if (ch == "`") {
						state.tokenize = tokenQuasi;
						return tokenQuasi(stream, state);
					} else if (ch == "#" && stream.peek() == "!") {
						stream.skipToEnd();
						return ret("meta", "meta");
					} else if (ch == "#" && stream.eatWhile(wordRE)) {
						return ret("variable", "property")
					} else if (ch == "<" && stream.match("!--") ||
						(ch == "-" && stream.match("->") && !/\S/.test(stream.string.slice(0, stream.start)))) {
						stream.skipToEnd()
						return ret("comment", "comment")
					} else if (isOperatorChar.test(ch)) {
						if (ch != ">" || !state.lexical || state.lexical.type != ">") {
							if (stream.eat("=")) {
								if (ch == "!" || ch == "=") stream.eat("=")
							} else if (/[<>*+\-|&?]/.test(ch)) {
								stream.eat(ch)
								if (ch == ">") stream.eat(ch)
							}
						}
						if (ch == "?" && stream.eat(".")) return ret(".")
						return ret("operator", "operator", stream.current());
					} else if (wordRE.test(ch)) {
						stream.eatWhile(wordRE);
						var word = stream.current()
						if (state.lastType != ".") {
							if (keywords.propertyIsEnumerable(word)) {
								var kw = keywords[word]
								return ret(kw.type, kw.style, word)
							}
							if (word == "async" && stream.match(/^(\s|\/\*([^*]|\*(?!\/))*?\*\/)*[\[\(\w]/, false))
								return ret("async", "keyword", word)
						}
						return ret("variable", "variable", word)
					}
				}
				function tokenString(quote) {
					return function(stream, state) {
						var escaped = false, next;
						if (jsonldMode && stream.peek() == "@" && stream.match(isJsonldKeyword)){
							state.tokenize = tokenBase;
							return ret("jsonld-keyword", "meta");
						}
						while ((next = stream.next()) != null) {
							if (next == quote && !escaped) break;
							escaped = !escaped && next == "\\";
						}
						if (!escaped) state.tokenize = tokenBase;
						return ret("string", "string");
					};
				}
				function tokenComment(stream, state) {
					var maybeEnd = false, ch;
					while (ch = stream.next()) {
						if (ch == "/" && maybeEnd) {
							state.tokenize = tokenBase;
							break;
						}
						maybeEnd = (ch == "*");
					}
					return ret("comment", "comment");
				}
				function tokenQuasi(stream, state) {
					var escaped = false, next;
					while ((next = stream.next()) != null) {
						if (!escaped && (next == "`" || next == "$" && stream.eat("{"))) {
							state.tokenize = tokenBase;
							break;
						}
						escaped = !escaped && next == "\\";
					}
					return ret("quasi", "string-2", stream.current());
				}
				var brackets = "([{}])";
				function findFatArrow(stream, state) {
					if (state.fatArrowAt) state.fatArrowAt = null;
					var arrow = stream.string.indexOf("=>", stream.start);
					if (arrow < 0) return;
					if (isTS) {
						var m = /:\s*(?:\w+(?:<[^>]*>|\[\])?|\{[^}]*\})\s*$/.exec(stream.string.slice(stream.start, arrow))
						if (m) arrow = m.index
					}
					var depth = 0, sawSomething = false;
					for (var pos = arrow - 1; pos >= 0; --pos) {
						var ch = stream.string.charAt(pos);
						var bracket = brackets.indexOf(ch);
						if (bracket >= 0 && bracket < 3) {
							if (!depth) { ++pos; break; }
							if (--depth == 0) { if (ch == "(") sawSomething = true; break; }
						} else if (bracket >= 3 && bracket < 6) {
							++depth;
						} else if (wordRE.test(ch)) {
							sawSomething = true;
						} else if (/["'\/`]/.test(ch)) {
							for (;; --pos) {
								if (pos == 0) return
								var next = stream.string.charAt(pos - 1)
								if (next == ch && stream.string.charAt(pos - 2) != "\\") { pos--; break }
							}
						} else if (sawSomething && !depth) {
							++pos;
							break;
						}
					}
					if (sawSomething && !depth) state.fatArrowAt = pos;
				}
				var atomicTypes = {"atom": true, "number": true, "variable": true, "string": true,
						"regexp": true, "this": true, "import": true, "jsonld-keyword": true};
				class JSLexical {
					var indented:Int;
					var column:Int;
					var type:String;
					var prev:Dynamic;
					var info:String;
					var align:Bool;
					public function new(indented:Int, column:Int, type:String, align:Bool, prev:Dynamic, info:String) {
						this.indented = indented;
						this.column = column;
						this.type = type;
						this.prev = prev;
						this.info = info;
						if (align != null) this.align = align;
					}
				}
				function inScope(state, varname) {
					if (!trackScope) return false
					for (var v = state.localVars; v; v = v.next)
						if (v.name == varname) return true;
					for (var cx = state.context; cx; cx = cx.prev) {
						for (var v = cx.vars; v; v = v.next)
							if (v.name == varname) return true;
					}
				}
				function parseJS(state, style, type, content, stream) {
					var cc = state.cc;
					cx.state = state; cx.stream = stream; cx.marked = null, cx.cc = cc; cx.style = style;
					if (!state.lexical.hasOwnProperty("align"))
						state.lexical.align = true;
					while(true) {
						var combinator = cc.length ? cc.pop() : jsonMode ? expression : statement;
						if (combinator(type, content)) {
							while(cc.length && cc[cc.length - 1].lex)
								cc.pop()();
							if (cx.marked) return cx.marked;
							if (type == "variable" && inScope(state, content)) return "variable-2";
							return style;
						}
					}
				}
				var cx = {state: null, column: null, marked: null, cc: null};
				function pass() {
					for (var i = arguments.length - 1; i >= 0; i--) cx.cc.push(arguments[i]);
				}
				function cont() {
					pass.apply(null, arguments);
					return true;
				}
				function inList(name, list) {
					for (var v = list; v; v = v.next) if (v.name == name) return true
					return false;
				}
				function register(varname) {
					var state = cx.state;
					cx.marked = "def";
					if (!trackScope) return
					if (state.context) {
						if (state
if (state.lexical.info == "var" && state.context && state.context.block) {
						var newContext = registerVarScoped(varname, state.context)
						if (newContext != null) {
							state.context = newContext
							return
						}
					} else if (!inList(varname, state.localVars)) {
						state.localVars = new Var(varname, state.localVars)
						return
					}
				}
				function registerVarScoped(varname, context) {
					if (!context) {
						return null
					} else if (context.block) {
						var inner = registerVarScoped(varname, context.prev)
						if (!inner) return null
						if (inner == context.prev) return context
						return new Context(inner, context.vars, true)
					} else if (inList(varname, context.vars)) {
						return context
					} else {
						return new Context(context.prev, new Var(varname, context.vars), false)
					}
				}
				function isModifier(name) {
					return name == "public" || name == "private" || name == "protected" || name == "abstract" || name == "readonly"
				}
				class Context {
					var prev:Dynamic;
					var vars:Dynamic;
					var block:Bool;
					public function new(prev:Dynamic, vars:Dynamic, block:Bool) {
						this.prev = prev;
						this.vars = vars;
						this.block = block;
					}
				}
				class Var {
					var name:String;
					var next:Dynamic;
					public function new(name:String, next:Dynamic) {
						this.name = name;
						this.next = next;
					}
				}
				var defaultVars = new Var("this", new Var("arguments", null))
				function pushcontext() {
					cx.state.context = new Context(cx.state.context, cx.state.localVars, false)
					cx.state.localVars = defaultVars
				}
				function pushblockcontext() {
					cx.state.context = new Context(cx.state.context, cx.state.localVars, true)
					cx.state.localVars = null
				}
				function popcontext() {
					cx.state.localVars = cx.state.context.vars
					cx.state.context = cx.state.context.prev
				}
				function pushlex(type, info) {
					var result = function() {
						var state = cx.state, indent = state.indented;
						if (state.lexical.type == "stat") indent = state.lexical.indented;
						else for (var outer = state.lexical; outer && outer.type == ")" && outer.align; outer = outer.prev)
							indent = outer.indented;
						state.lexical = new JSLexical(indent, cx.stream.column(), type, null, state.lexical, info);
					};
					result.lex = true;
					return result;
				}
				function poplex() {
					var state = cx.state;
					if (state.lexical.prev) {
						if (state.lexical.type == ")")
							state.indented = state.lexical.indented;
						state.lexical = state.lexical.prev;
					}
				}
				function expect(wanted) {
					function exp(type) {
						if (type == wanted) return cont();
						else if (wanted == ";" || type == "}" || type == ")" || type == "]") return pass();
						else return cont(exp);
					};
					return exp;
				}
				function statement(type, value) {
					if (type == "var") return cont(pushlex("vardef", value), vardef, expect(";"), poplex);
					if (type == "keyword a") return cont(pushlex("form"), parenExpr, statement, poplex);
					if (type == "keyword b") return cont(pushlex("form"), statement, poplex);
					if (type == "keyword d") return cx.stream.match(/^\s*$/, false) ? cont() : cont(pushlex("stat"), maybeexpression, expect(";"), poplex);
					if (type == "debugger") return cont(expect(";"));
					if (type == "{") return cont(pushlex("}"), pushblockcontext, block, poplex, popcontext);
					if (type == ";") return cont();
					if (type == "if") {
						if (cx.state.lexical.info == "else" && cx.state.cc[cx.state.cc.length - 1] == poplex)
							cx.state.cc.pop()();
						return cont(pushlex("form"), parenExpr, statement, poplex, maybeelse);
					}
					if (type == "function") return cont(functiondef);
					if (type == "for") return cont(pushlex("form"), pushblockcontext, forspec, statement, popcontext, poplex);
					if (type == "class" || (isTS && value == "interface")) {
						cx.marked = "keyword"
						return cont(pushlex("form", type == "class" ? type : value), className, poplex)
					}
					if (type == "variable") {
						if (isTS && value == "declare") {
							cx.marked = "keyword"
							return cont(statement)
						} else if (isTS && (value == "module" || value == "enum" || value == "type") && cx.stream.match(/^\s*\w/, false)) {
							cx.marked = "keyword"
							if (value == "enum") return cont(enumdef);
							else if (value == "type") return cont(typename, expect("operator"), typeexpr, expect(";"));
							else return cont(pushlex("form"), pattern, expect("{"), pushlex("}"), block, poplex, poplex)
						} else if (isTS && value == "namespace") {
							cx.marked = "keyword"
							return cont(pushlex("form"), expression, statement, poplex)
						} else if (isTS && value == "abstract") {
							cx.marked >>>