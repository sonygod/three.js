import Program.FunctionDeclaration;
import Program.For;
import Program.AccessorElements;
import Program.Ternary;
import Program.Varying;
import Program.DynamicElement;
import Program.StaticElement;
import Program.FunctionParameter;
import Program.Unary;
import Program.Conditional;
import Program.VariableDeclaration;
import Program.Operator;
import Program.Number;
import Program.String;
import Program.FunctionCall;
import Program.Return;
import Program.Accessor;
import Program.Uniform;

class Token {
	public static var LINE:String = 'line';
	public static var COMMENT:String = 'comment';
	public static var NUMBER:String = 'number';
	public static var STRING:String = 'string';
	public static var LITERAL:String = 'literal';
	public static var OPERATOR:String = 'operator';

	public var tokenizer:Tokenizer;
	public var type:String;
	public var str:String;
	public var pos:Int;
	public var tag:Null<Token>;

	public function get endPos():Int {
		return this.pos + this.str.length;
	}

	public function get isNumber():Bool {
		return this.type == Token.NUMBER;
	}

	public function get isString():Bool {
		return this.type == Token.STRING;
	}

	public function get isLiteral():Bool {
		return this.type == Token.LITERAL;
	}

	public function get isOperator():Bool {
		return this.type == Token.OPERATOR;
	}

	public function new(tokenizer:Tokenizer, type:String, str:String, pos:Int) {
		this.tokenizer = tokenizer;
		this.type = type;
		this.str = str;
		this.pos = pos;
		this.tag = null;
	}
}

class Tokenizer {
	public var source:String;
	public var position:Int;
	public var tokens:Array<Token>;

	public function new(source:String) {
		this.source = source;
		this.position = 0;
		this.tokens = [];
	}

	public function tokenize():Tokenizer {
		var token:Token = this.readToken();
		while (token != null) {
			this.tokens.push(token);
			token = this.readToken();
		}
		return this;
	}

	public function skip(...params:Array<Dynamic>):String {
		var remainingCode:String = this.source.substr(this.position);
		var i:Int = params.length;
		while (i-- > 0) {
			var skip:RegExpMatchArray = params[i].match(remainingCode);
			var skipLength:Int = skip != null ? skip[0].length : 0;
			if (skipLength > 0) {
				this.position += skipLength;
				remainingCode = this.source.substr(this.position);
				i = params.length;
			}
		}
		return remainingCode;
	}

	public function readToken():Token {
		var remainingCode:String = this.skip(spaceRegExp);
		for (var i:Int = 0; i < TokenParserList.length; i++) {
			var parser:Dynamic = TokenParserList[i];
			var result:RegExpMatchArray = parser.regexp.match(remainingCode);
			if (result != null) {
				var token:Token = new Token(this, parser.type, result[parser.group || 0], this.position);
				this.position += result[0].length;
				if (parser.isTag) {
					var nextToken:Token = this.readToken();
					if (nextToken != null) {
						nextToken.tag = token;
					}
					return nextToken;
				}
				return token;
			}
		}
		return null;
	}
}

class GLSLDecoder {
	public var index:Int;
	public var tokenizer:Tokenizer;
	public var keywords:Array<Dynamic>;
	private var _currentFunction:FunctionDeclaration;

	public function new() {
		this.index = 0;
		this.tokenizer = null;
		this.keywords = [];
		this._currentFunction = null;
		this.addPolyfill('gl_FragCoord', 'vec3 gl_FragCoord = vec3(viewportCoordinate.x, viewportCoordinate.y.oneMinus(), viewportCoordinate.z);');
	}

	public function addPolyfill(name:String, polyfill:String):GLSLDecoder {
		this.keywords.push({name: name, polyfill: polyfill});
		return this;
	}

	public function get tokens():Array<Token> {
		return this.tokenizer.tokens;
	}

	public function readToken():Token {
		return this.tokens[this.index++];
	}

	public function getToken(offset:Int = 0):Token {
		return this.tokens[this.index + offset];
	}

	public function getTokensUntil(str:String, tokens:Array<Token>, offset:Int = 0):Array<Token> {
		var output:Array<Token> = [];
		var groupIndex:Int = 0;
		for (var i:Int = offset; i < tokens.length; i++) {
			var token:Token = tokens[i];
			groupIndex += getGroupDelta(token.str);
			output.push(token);
			if (groupIndex == 0 && token.str == str) {
				break;
			}
		}
		return output;
	}

	public function readTokensUntil(str:String):Array<Token> {
		var tokens:Array<Token> = this.getTokensUntil(str, this.tokens, this.index);
		this.index += tokens.length;
		return tokens;
	}

	public function parseExpressionFromTokens(tokens:Array<Token>):Dynamic {
		if (tokens.length == 0) return null;
		var firstToken:Token = tokens[0];
		var lastToken:Token = tokens[tokens.length - 1];
		// Precedence operators
		var groupIndex:Int = 0;
		for (var operator in precedenceOperators) {
			for (var i:Int = 0; i < tokens.length; i++) {
				var token:Token = tokens[i];
				groupIndex += getGroupDelta(token.str);
				if (!token.isOperator || i == 0 || i == tokens.length - 1) continue;
				if (groupIndex == 0 && token.str == operator) {
					if (operator == '?') {
						var conditionTokens:Array<Token> = tokens.slice(0, i);
						var leftTokens:Array<Token> = this.getTokensUntil(':', tokens, i + 1).slice(0, -1);
						var rightTokens:Array<Token> = tokens.slice(i + leftTokens.length + 2);
						var condition:Dynamic = this.parseExpressionFromTokens(conditionTokens);
						var left:Dynamic = this.parseExpressionFromTokens(leftTokens);
						var right:Dynamic = this.parseExpressionFromTokens(rightTokens);
						return new Ternary(condition, left, right);
					} else {
						var left:Dynamic = this.parseExpressionFromTokens(tokens.slice(0, i));
						var right:Dynamic = this.parseExpressionFromTokens(tokens.slice(i + 1, tokens.length));
						return this._evalOperator(new Operator(operator, left, right));
					}
				}
				if (groupIndex < 0) {
					return this.parseExpressionFromTokens(tokens.slice(0, i));
				}
			}
		}
		// Unary operators (before)
		if (firstToken.isOperator) {
			for (var operator in unaryOperators) {
				if (firstToken.str == operator) {
					var right:Dynamic = this.parseExpressionFromTokens(tokens.slice(1));
					return new Unary(operator, right);
				}
			}
		}
		// Unary operators (after)
		if (lastToken.isOperator) {
			for (var operator in unaryOperators) {
				if (lastToken.str == operator) {
					var left:Dynamic = this.parseExpressionFromTokens(tokens.slice(0, tokens.length - 1));
					return new Unary(operator, left, true);
				}
			}
		}
		// Groups
		if (firstToken.str == '(') {
			var leftTokens:Array<Token> = this.getTokensUntil(')', tokens);
			var left:Dynamic = this.parseExpressionFromTokens(leftTokens.slice(1, leftTokens.length - 1));
			var operator:Token = tokens[leftTokens.length];
			if (operator != null) {
				var rightTokens:Array<Token> = tokens.slice(leftTokens.length + 1);
				var right:Dynamic = this.parseExpressionFromTokens(rightTokens);
				return this._evalOperator(new Operator(operator.str, left, right));
			}
			return left;
		}
		// Primitives and accessors
		if (firstToken.isNumber) {
			var type:String;
			var isHex:Bool = /^(0x)/.test(firstToken.str);
			if (isHex) type = 'int';
			else if (/u$/.test(firstToken.str)) type = 'uint';
			else if (/f|e|\./.test(firstToken.str)) type = 'float';
			else type = 'int';
			var str:String = firstToken.str.replace(/u|i$/, '');
			if (isHex == false) {
				str = str.replace(/f$/, '');
			}
			return new Number(str, type);
		} else if (firstToken.isString) {
			return new String(firstToken.str);
		} else if (firstToken.isLiteral) {
			if (firstToken.str == 'return') {
				return new Return(this.parseExpressionFromTokens(tokens.slice(1)));
			}
			var secondToken:Token = tokens[1];
			if (secondToken != null) {
				if (secondToken.str == '(') {
					// Function call
					var paramsTokens:Array<Token> = this.parseFunctionParametersFromTokens(tokens.slice(2, tokens.length - 1));
					return new FunctionCall(firstToken.str, paramsTokens);
				} else if (secondToken.str == '[') {
					// Array accessor
					var elements:Array<Dynamic> = [];
					var currentTokens:Array<Token> = tokens.slice(1);
					while (currentTokens.length > 0) {
						var token:Token = currentTokens[0];
						if (token.str == '[') {
							var accessorTokens:Array<Token> = this.getTokensUntil(']', currentTokens);
							var element:Dynamic = this.parseExpressionFromTokens(accessorTokens.slice(1, accessorTokens.length - 1));
							currentTokens = currentTokens.slice(accessorTokens.length);
							elements.push(new DynamicElement(element));
						} else if (token.str == '.') {
							var accessorTokens:Array<Token> = currentTokens.slice(1, 2);
							var element:Dynamic = this.parseExpressionFromTokens(accessorTokens);
							currentTokens = currentTokens.slice(2);
							elements.push(new StaticElement(element));
						} else {
							console.error('Unknown accessor expression', token);
							break;
						}
					}
					return new AccessorElements(firstToken.str, elements);
				}
			}
			return new Accessor(firstToken.str);
		}
	}

	public function parseFunctionParametersFromTokens(tokens:Array<Token>):Array<Dynamic> {
		if (tokens.length == 0) return [];
		var expression:Dynamic = this.parseExpressionFromTokens(tokens);
		var params:Array<Dynamic> = [];
		var current:Dynamic = expression;
		while (current.type == ',') {
			params.push(current.left);
			current = current.right;
		}
		params.push(current);
		return params;
	}

	public function parseExpression():Dynamic {
		var tokens:Array<Token> = this.readTokensUntil(';');
		var exp:Dynamic = this.parseExpressionFromTokens(tokens.slice(0, tokens.length - 1));
		return exp;
	}

	public function parseFunctionParams(tokens:Array<Token>):Array<FunctionParameter> {
		var params:Array<FunctionParameter> = [];
		for (var i:Int = 0; i < tokens.length; i++) {
			var immutable:Bool = tokens[i].str == 'const';
			if (immutable) i++;
			var qualifier:String = tokens[i].str;
			if (/^(in|out|inout)$/.test(qualifier)) {
				i++;
			} else {
				qualifier = null;
			}
			var type:String = tokens[i++].str;
			var name:String = tokens[i++].str;
			params.push(new FunctionParameter(type, name, qualifier, immutable));
			if (tokens[i] != null && tokens[i].str != ',') throw new Error('Expected ","');
		}
		return params;
	}

	public function parseFunction():FunctionDeclaration {
		var type:String = this.readToken().str;
		var name:String = this.readToken().str;
		var paramsTokens:Array<Token> = this.readTokensUntil(')');
		var params:Array<FunctionParameter> = this.parseFunctionParams(paramsTokens.slice(1, paramsTokens.length - 1));
		var func:FunctionDeclaration = new FunctionDeclaration(type, name, params);
		this._currentFunction = func;
		this.parseBlock(func);
		this._currentFunction = null;
		return func;
	}

	public function parseVariablesFromToken(tokens:Array<Token>, type:String):VariableDeclaration {
		var index:Int = 0;
		var immutable:Bool = tokens[0].str == 'const';
		if (immutable) index++;
		type = type || tokens[index++].str;
		var name:String = tokens[index++].str;
		var token:Token = tokens[index];
		var init:Dynamic = null;
		var next:Dynamic = null;
		if (token != null) {
			var initTokens:Array<Token> = this.getTokensUntil(',', tokens, index);
			if (initTokens[0].str == '=') {
				var expressionTokens:Array<Token> = initTokens.slice(1);
				if (expressionTokens[expressionTokens.length - 1].str == ',') expressionTokens.pop();
				init = this.parseExpressionFromTokens(expressionTokens);
			}
			var nextTokens:Array<Token> = tokens.slice(initTokens.length + (index - 1));
			if (nextTokens[0] != null && nextTokens[0].str == ',') {
				next = this.parseVariablesFromToken(nextTokens.slice(1), type);
			}
		}
		var variable:VariableDeclaration = new VariableDeclaration(type, name, init, next, immutable);
		return variable;
	}

	public function parseVariables():VariableDeclaration {
		var tokens:Array<Token> = this.readTokensUntil(';');
		return this.parseVariablesFromToken(tokens.slice(0, tokens.length - 1));
	}

	public function parseUniform():Uniform {
		var tokens:Array<Token> = this.readTokensUntil(';');
		var type:String = tokens[1].str;
		var name:String = tokens[2].str;
		return new Uniform(type, name);
	}

	public function parseVarying():Varying {
		var tokens:Array<Token> = this.readTokensUntil(';');
		var type:String = tokens[1].str;
		var name:String = tokens[2].str;
		return new Varying(type, name);
	}

	public function parseReturn():Return {
		this.readToken(); // Skip 'return'
		var expression:Dynamic = this.parseExpression();
		return new Return(expression);
	}

	public function parseFor():For {
		this.readToken(); // Skip 'for'
		var forTokens:Array<Token> = this.readTokensUntil(')').slice(1, -1);
		var initializationTokens:Array<Token> = this.getTokensUntil(';', forTokens, 0).slice(0, -1);
		var conditionTokens:Array<Token> = this.getTokensUntil(';', forTokens, initializationTokens.length + 1).slice(0, -1);
		var afterthoughtTokens:Array<Token> = forTokens.slice(initializationTokens.length + conditionTokens.length + 2);
		var initialization:Dynamic;
		if (initializationTokens[0] != null && isType(initializationTokens[0].str)) {
			initialization = this.parseVariablesFromToken(initializationTokens);
		} else {
			initialization = this.parseExpressionFromTokens(initializationTokens);
		}
		var condition:Dynamic = this.parseExpressionFromTokens(conditionTokens);
		var afterthought:Dynamic = this.parseExpressionFromTokens(afterthoughtTokens);
		var statement:For = new For(initialization, condition, afterthought);
		if (this.getToken().str == '{') {
			this.parseBlock(statement);
		} else {
			statement.body.push(this.parseExpression());
		}
		return statement;
	}

	public function parseIf():Conditional {
		var parseIfExpression:Void -> Dynamic = function() {
			this.readToken(); // Skip 'if'
			var condTokens:Array<Token> = this.readTokensUntil(')');
			return this.parseExpressionFromTokens(condTokens.slice(1, condTokens.length - 1));
		};
		var parseIfBlock:Dynamic -> Void = function(cond:Dynamic) {
			if (this.getToken().str == '{') {
				this.parseBlock(cond);
			} else {
				cond.body.push(this.parseExpression());
			}
		};
		//
		var conditional:Conditional = new Conditional(parseIfExpression());
		parseIfBlock(conditional);
		//
		var current:Conditional = conditional;
		while (this.getToken() != null && this.getToken().str == 'else') {
			this.readToken(); // Skip 'else'
			var previous:Conditional = current;
			if (this.getToken().str == 'if') {
				current = new Conditional(parseIfExpression());
			} else {
				current = new Conditional();
			}
			previous.elseConditional = current;
			parseIfBlock(current);
		}
		return conditional;
	}

	public function parseBlock(scope:Dynamic):Void {
		var firstToken:Token = this.getToken();
		if (firstToken.str == '{') {
			this.readToken(); // Skip '{'
		}
		var groupIndex:Int = 0;
		while (this.index < this.tokens.length) {
			var token:Token = this.getToken();
			var statement:Dynamic = null;
			groupIndex += getGroupDelta(token.str);
			if (groupIndex < 0) {
				this.readToken(); // Skip '}'
				break;
			}
			//
			if (token.isLiteral) {
				if (token.str == 'const') {
					statement = this.parseVariables();
				} else if (token.str == 'uniform') {
					statement = this.parseUniform();
				} else if (token.str == 'varying') {
					statement = this.parseVarying();
				} else if (isType(token.str)) {
					if (this.getToken(2).str == '(') {
						statement = this.parseFunction();
					} else {
						statement = this.parseVariables();
					}
				} else if (token.str == 'return') {
					statement = this.parseReturn();
				} else if (token.str == 'if') {
					statement = this.parseIf();
				} else if (token.str == 'for') {
					statement = this.parseFor();
				} else {
					statement = this.parseExpression();
				}
			}
			if (statement != null) {
				scope.body.push(statement);
			} else {
				this.index++;
			}
		}
	}

	private function _evalOperator(operator:Operator):Operator {
		if (operator.type.includes('=')) {
			var parameter:FunctionParameter = this._getFunctionParameter(operator.left.property);
			if (parameter != null) {
				// Parameters are immutable in WGSL
				parameter.immutable = false;
			}
		}
		return operator;
	}

	private function _getFunctionParameter(name:String):FunctionParameter {
		if (this._currentFunction != null) {
			for (param in this._currentFunction.params) {
				if (param.name == name) {
					return param;
				}
			}
		}
		return null;
	}

	public function parse(source:String):Program {
		var polyfill:String = '';
		for (keyword in this.keywords) {
			if (new RegExp('(^|\\b)' + keyword.name + '($|\\b)', 'gm').test(source)) {
				polyfill += keyword.polyfill + '\n';
			}
		}
		if (polyfill != '') {
			polyfill = '// Polyfills\n\n' + polyfill + '\n';
		}
		this.index = 0;
		this.tokenizer = new Tokenizer(polyfill + source).tokenize();
		var program:Program = new Program();
		this.parseBlock(program);
		return program;
	}
}