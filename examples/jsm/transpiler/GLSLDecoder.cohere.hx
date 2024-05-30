import haxe.Serializer;
import haxe.Unserializer;

class Token {
	var tokenizer:Tokenizer;
	var type:String;
	var str:String;
	var pos:Int;
	var tag:Token;

	public function new(tokenizer:Tokenizer, type:String, str:String, pos:Int) {
		this.tokenizer = tokenizer;
		this.type = type;
		this.str = str;
		this.pos = pos;
	}

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

	static var LINE:String = "line";
	static var COMMENT:String = "comment";
	static var NUMBER:String = "number";
	static var STRING:String = "string";
	static var LITERAL:String = "literal";
	static var OPERATOR:String = "operator";
}

class Tokenizer {
	var source:String;
	var position:Int;
	var tokens:Array<Token>;

	public function new(source:String) {
		this.source = source;
		this.position = 0;
		this.tokens = [];
	}

	public function tokenize():Tokenizer {
		var token = this.readToken();
		while (token != null) {
			this.tokens.push(token);
			token = this.readToken();
		}
		return this;
	}

	private function skip(...params) {
		var remainingCode = this.source.substr(this.position);
		for (param in params) {
			var skip = params[param].exec(remainingCode);
			if (skip != null) {
				this.position += skip[0].length;
				remainingCode = this.source.substr(this.position);
			}
		}
		return remainingCode;
	}

	private function readToken():Token? {
		var remainingCode = this.skip(spaceRegExp);
		for (parser in TokenParserList) {
			var result = parser.regexp.exec(remainingCode);
			if (result != null) {
				var token = new Token(this, parser.type, result[parser.group ?? 0], this.position);
				this.position += result[0].length;
				if (parser.isTag) {
					var nextToken = this.readToken();
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

	static var spaceRegExp = /^((\t| )\n*)+/;
	static var lineRegExp = /^\n+/;
	static var commentRegExp = /^\/\*[\s\S]*?\*\//;
	static var inlineCommentRegExp = /^\/\/.*?(\n|$)/;
	static var numberRegExp = /^((0x\w+)|(\.?\d+\.?\d*((e-?\d+)|\w)?))/;
	static var stringDoubleRegExp = /^(\"((?:[^"\\]|\\.)*)\")/;
	static var stringSingleRegExp = /^(\'((?:[^\'\\]|\\.)*)\')/;
	static var literalRegExp = /^[A-Za-z](\w|\.)*/;
	static var operatorsRegExp = new EReg('^(\\' + [
		'<<=', '>>=', '++', '--', '<<', '>>', '+=', '-=', '*=', '/=', '%=', '&=', '^^', '^=', '|=',
		'<=', '>=', '==', '!=', '&&', '||',
		'(', ')', '[', ']', '{', '}',
		'.', ',', ';', '!', '=', '~', '*', '/', '%', '+', '-', '<', '>', '&', '^', '|', '?', ':', '#'
	].join('$').split('').join('\\').replace(/\\\$/g, '|'), ')');

	static var TokenParserList = [
		{ type: Token.LINE, regexp: lineRegExp, isTag: true },
		{ type: Token.COMMENT, regexp: commentRegExp, isTag: true },
		{ type: Token.COMMENT, regexp: inlineCommentRegExp, isTag: true },
		{ type : Token.NUMBER, regexp : numberRegExp },
		{ type : Token.STRING, regexp : stringDoubleRegExp, group : 2 },
		{ type : Token.STRING, regexp : stringSingleRegExp, group : 2 },
		{ type : Token.LITERAL, regexp : literalRegExp },
		{ type : Token.OPERATOR, regexp : operatorsRegExp }
	];
}

class GLSLDecoder {
	var index:Int;
	var tokenizer:Tokenizer;
	var keywords:Array<{ name:String, polyfill:String }>;

	public function new() {
		this.index = 0;
		this.tokenizer = null;
		this.keywords = [];
		this.addPolyfill('gl_FragCoord', 'vec3 gl_FragCoord = vec3( viewportCoordinate.x, viewportCoordinate.y.oneMinus(), viewportCoordinate.z );');
	}

	public function addPolyfill(name:String, polyfill:String):GLSLDecoder {
		this.keywords.push({ name: name, polyfill: polyfill });
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
		var output = [];
		var groupIndex = 0;
		for (i in 0...tokens.length) {
			var token = tokens[i];
			groupIndex += getGroupDelta(token.str);
			output.push(token);
			if (groupIndex == 0 && token.str == str) {
				break;
			}
		}
		return output;
	}

	public function readTokensUntil(str:String):Array<Token> {
		var tokens = this.getTokensUntil(str, this.tokens, this.index);
		this.index += tokens.length;
		return tokens;
	}

	private function parseExpressionFromTokens(tokens:Array<Token>):Expression {
		if (tokens.length == 0) return null;

		var firstToken = tokens[0];
		var lastToken = tokens[tokens.length - 1];

		// precedence operators
		var groupIndex = 0;
		for (operator in precedenceOperators) {
			for (i in 0...tokens.length) {
				var token = tokens[i];
				groupIndex += getGroupDelta(token.str);
				if (!token.isOperator || i == 0 || i == tokens.length - 1) continue;
				if (groupIndex == 0 && token.str == operator) {
					if (operator == '?') {
						var conditionTokens = tokens.slice(0, i);
						var leftTokens = this.getTokensUntil(':', tokens, i + 1).slice(0, -1);
						var rightTokens = tokens.slice(i + leftTokens.length + 2);
						var condition = this.parseExpressionFromTokens(conditionTokens);
						var left = this.parseExpressionFromTokens(leftTokens);
						var right = this.parseExpressionFromTokens(rightTokens);
						return new Ternary(condition, left, right);
					} else {
						var left = this.parseExpressionFromTokens(tokens.slice(0, i));
						var right = this.parseExpressionFromTokens(tokens.slice(i + 1, tokens.length));
						return this._evalOperator(new Operator(operator, left, right));
					}
				}
				if (groupIndex < 0) {
					return this.parseExpressionFromTokens(tokens.slice(0, i));
				}
			}
		}

		// unary operators (before)
		if (firstToken.isOperator) {
			for (operator in unaryOperators) {
				if (firstToken.str == operator) {
					var right = this.parseExpressionFromTokens(tokens.slice(1));
					return new Unary(operator, right);
				}
			}
		}

		// unary operators (after)
		if (lastToken.isOperator) {
			for (operator in unaryOperators) {
				if (lastToken.str == operator) {
					var left = this.parseExpressionFromTokens(tokens.slice(0, tokens.length - 1));
					return new Unary(operator, left, true);
				}
			}
		}

		// groups
		if (firstToken.str == '(') {
			var leftTokens = this.getTokensUntil(')', tokens);
			var left = this.parseExpressionFromTokens(leftTokens.slice(1, leftTokens.length - 1));
			var operator = tokens[leftTokens.length];
			if (operator != null) {
				var rightTokens = tokens.slice(leftTokens.length + 1);
				var right = this.parseExpressionFromTokens(rightTokens);
				return this._evalOperator(new Operator(operator.str, left, right));
			}
			return left;
		}

		// primitives and accessors
		if (firstToken.isNumber) {
			var type:String;
			var isHex = /^(0x)/.test(firstToken.str);
			if (isHex) type = 'int';
			else if (/u$/.test(firstToken.str)) type = 'uint';
			else if (/f|e|\./.test(firstToken.str)) type = 'float';
			else type = 'int';
			var str = firstToken.str.replace(/u|i$/, '');
			if (!isHex) {
				str = str.replace(/f$/, '');
			}
			return new Number(str, type);
		} else if (firstToken.isString) {
			return new String(firstToken.str);
		} else if (firstToken.isLiteral) {
			if (firstToken.str == 'return') {
				return new Return(this.parseExpressionFromTokens(tokens.slice(1)));
			}
			var secondToken = tokens[1];
			if (secondToken != null) {
				if (secondToken.str == '(') {
					// function call
					var paramsTokens = this.parseFunctionParametersFromTokens(tokens.slice(2, tokens.length - 1));
					return new FunctionCall(firstToken.str, paramsTokens);
				} else if (secondToken.str == '[') {
					// array accessor
					var elements = [];
					var currentTokens = tokens.slice(1);
					while (currentTokens.length > 0) {
						var token = currentTokens[0];
						if (token.str == '[') {
							var accessorTokens = this.getTokensUntil(']', currentTokens);
							var element = this.parseExpressionFromTokens(accessorTokens.slice(1, accessorTokens.length - 1));
							currentTokens = currentTokens.slice(accessorTokens.length);
							elements.push(new DynamicElement(element));
						} else if (token.str == '.') {
							var accessorTokens = currentTokens.slice(1, 2);
							var element = this.parseExpressionFromTokens(accessorTokens);
							currentTokens = currentTokens.slice(2);
							elements.push(new StaticElement(element));
						} else {
							throw new Error('Unknown accessor expression: ' + token);
						}
					}
					return new AccessorElements(firstToken.str, elements);
				}
			}
			return new Accessor(firstToken.str);
		}
	}

	private function parseFunctionParametersFromTokens(tokens:Array<Token>):Array<Expression> {
		if (tokens.length == 0) return [];
		var expression = this.parseExpressionFromTokens(tokens);
		var params = [];
		var current = expression;
		while (current.type == ',') {
			params.push(current.left);
			current = current.right;
		}
		params.push(current);
		return params;
	}

	public function parseExpression():Expression {
		var tokens = this.readTokensUntil(';');
		var exp = this.parseExpressionFromTokens(tokens.slice(0, tokens.length - 1));
		return exp;
	}

	private function parseFunctionParams(tokens:Array<Token>):Array<FunctionParameter> {
		var params = [];
		for (i in 0...tokens.length) {
			var immutable = tokens[i].str == 'const';
			if (immutable) i++;
			var qualifier = tokens[i].str;
			if (/^(in|out|inout)$/.test(qualifier)) {
				i++;
			} else {
				qualifier = null;
			}
			var type = tokens[i++].str;
			var name = tokens[i++].str;
			params.push(new FunctionParameter(type, name, qualifier, immutable));
			if (tokens[i] != null && tokens[i].str != ',') throw new Error('Expected ","');
		}
		return params;
	}

	public function parseFunction():FunctionDeclaration {
		var type = this.readToken().str;
		var name = this.readToken().str;
		var paramsTokens = this.readTokensUntil(')');
		var params = this.parseFunctionParams(paramsTokens.slice(1, paramsTokens.length - 1));
		var func = new FunctionDeclaration(type, name, params);
		this._currentFunction = func;
		this.parseBlock(func);
		this._currentFunction = null;
		return func;
	}

	private function parseVariablesFromToken(tokens:Array<Token>, type:String):VariableDeclaration {
		var index = 0;
		var immutable = tokens[0].str == 'const';
		if (immutable) index++;
		type = type ?? tokens[index++].str;
		var name = tokens[index++].str;
		var token = tokens[index];
		var init:Expression = null;
		var next:VariableDeclaration = null;
		if (token != null) {
			var initTokens = this.getTokensUntil(',', tokens, index);
			if (initTokens[0].str == '=') {
				var expressionTokens = initTokens.slice(1);
				if (expressionTokens[expressionTokens.length - 1].str == ',') expressionTokens.pop();
				init = this.parseExpressionFromTokens(expressionTokens);
			}
			var nextTokens = tokens.slice(initTokens.length + (index - 1));
			if (nextTokens[0] != null && nextTokens[0].str == ',') {
				next = this.parseVariablesFromToken(nextTokens.slice(1), type);
			}
		}
		var variable = new VariableDeclaration(type, name, init, next, immutable);
		return variable;
	}

	public function parseVariables():VariableDeclaration {
		var tokens = this.readTokensUntil(';');
		return this.parseVariablesFromToken(tokens.slice(0, tokens.length - 1));
	}

	public function parseUniform():Uniform {
		var tokens = this.readTokensUntil(';');
		var type = tokens[1].str;
		var name = tokens[2].str;
		return new Uniform(type, name);
	}

	public function parseVarying():Varying {
		var tokens = this.readTokensUntil(';');
		var type = tokens[1].str;
		var name = tokens[2].str;
		return new Varying(type, name);
	}

	public function parseReturn():Return {
		this.readToken(); // skip 'return'
		var expression = this.parseExpression();
		return new Return(expression);
	}

	public function parseFor():For {
		this.readToken(); // skip 'for'
		var forTokens = this.readTokensUntil(')').slice(1, -1);
		var initializationTokens = this.getTokensUntil(';', forTokens, 0).slice(0, -1);
		var conditionTokens = this.getTokensUntil(';', forTokens, initializationTokens.length + 1).slice(0, -1);
		var afterthoughtTokens = forTokens.slice(initializationTokens.length + conditionTokens.length + 2);
		var initialization:Expression;
		if (isType(initializationTokens[0].str)) {
			initialization = this.parseVariablesFromToken(initializationTokens);
		} else {
			initialization = this.parseExpressionFromTokens(initializationTokens);
		}
		var condition = this.parseExpressionFromTokens(conditionTokens);
		var afterthought = this.parseExpressionFromTokens(afterthoughtTokens);
		var statement = new For(initialization, condition, afterthought);
		if (this.getToken().str == '{') {
			this.parseBlock(statement);
		} else {
			statement.body.push(this.parseExpression());
		}
		return statement;
	}

	public function parseIf():Conditional {
		function parseIfExpression():Expression {
			this.readToken(); // skip 'if'
			var condTokens = this.readTokensUntil(')');
			return this.parseExpressionFromTokens(condTokens.slice(1, condTokens.length - 1));
		}

		function parseIfBlock(cond:Conditional):Void {
			if (this.getToken().str == '{') {
				this.parseBlock(cond);
			} else {
				cond.body.push(this.parseExpression());
			}
		}

		var conditional = new Conditional(parseIfExpression());
		parseIfBlock(conditional);
		var current = conditional;
		while (this.getToken() != null && this.getToken().str == 'else') {
			this.readToken(); // skip 'else'
			var previous = current;
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

	public function parseBlock(scope:Scope):Void {
		var firstToken = this.getToken();
		if (firstToken.str == '{') {
			this.readToken(); // skip '{'
		}
		var groupIndex = 0;
		while (this.index < this.tokens.length) {
			var token = this.getToken();
			groupIndex += getGroupDelta(token.str);
			if (groupIndex < 0) {
				this.readToken(); // skip '}'
				break;
			}
			if (token.isLiteral) {
				if (token.str == 'const') {
					scope.body.push(this.parseVariables());
				} else if (token.str == 'uniform') {
					scope.body.push(this.parseUniform());
				} else if (token.str == 'varying') {
					scope.body.push(this.parseVarying());
				} else if (isType(token.str)) {
					if (this.getToken(2).str == '(') {
						scope.body.push(this.parseFunction());
					} else {
						scope.body.push(this.parseVariables());
					}
				} else if (token.str == 'return') {
					scope.body.push(this.parseReturn());
				} else if (token.str == 'if') {
					scope.body.push(this.parseIf());
				} else if (token.str == 'for') {
					scope.body.push(this.parseFor());
				} else {
					scope.body.push(this.parseExpression());
				}
			} else {
				this.index++;
			}
		}
	}

	private function _evalOperator(operator:Operator):Operator {
		if (operator.type.includes('=')) {
			var parameter = this._getFunctionParameter(operator.left.property);
			if (parameter != null) {
				// Parameters are immutable in WGSL
				parameter.immutable = false;
			}
		}
		return operator;
	}

	private function _getFunctionParameter(name:String):FunctionParameter? {
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
		var polyfill = '';
		for (keyword in this.keywords) {
			if (new EReg('(^|\\b)' + keyword.name + '($|\\b)', 'gm').match(source)) {
				polyfill += keyword.polyfill + '\n';
			}
		}
		if (polyfill != '') {
			polyfill = '// Polyfills\n\n' + polyfill + '\n';
		}
		this.index = 0;
		this.tokenizer = new Tokenizer(polyfill + source).tokenize();
		var program = new Program();
		this.parseBlock(program);
		return program;
	}

	static function isType(str:String):Bool {
		return /void|bool|float|u?int|(u|i)?vec[234]/.test(str);
	}

	static function getGroupDelta(str:String):Int {
		switch (str) {
			case '(': case '[': case '{': return 1;
			case ')': case ']': case '}': return -1;
			default: return 0;
		}
	}

	var _currentFunction:FunctionDeclaration? = null;
}

class Expression {
	public function toCode():String {
		throw new Error('Not implemented');
	}
}

class Number extends Expression {
	var value:String;
	var type:String;

	public function new(value:String, type:String) {
		this.value = value;
		this.type = type;
	}

	override public function toCode():String {
		return this.value + ' ' + this.type;
	}
}

class String extends Expression {
	var value:String;

	public function new(value:String) {
		this.value = value;
	}

	override public function toCode():String {
		return '"' + this.value + '"';
	}
}

class Accessor extends Expression {
	var property:String;

	public function new(property:String) {
		this.property = property;
	}

	override public function toCode():String {
		return this.property;
	}
}

class AccessorElements extends Accessor {
	var elements:Array<Element>;

	public function new(property:String, elements:Array<Element>) {
		this.property = property;
		this.elements = elements;
	}

	override public function toCode():String {
		var code = this.property;
		for (element in this.elements) {
			code += element.toCode();
		}
		return code;
	}
}

class Element {
	public function toCode():String {
		throw new Error('Not implemented');
	}
}

class StaticElement extends Element {
	var element:Expression;

	public function new(element:Expression) {
		this.element = element;
	}

	override public function toCode():String {
		return '.' + this.element.toCode();
	}
}

class DynamicElement extends Element {
	var element:Expression;

	public function new(element:Expression) {
		this.element = element;
	}

	override public function toCode():String {
		return '[' + this.element.toCode() + ']';
	}
}

class Operator extends Expression {
	var type:String;
	var left:Expression;
	var right:Expression;

	public function new(type:String, left:Expression, right:Expression) {
		this.type = type;
		this.left = left;
		this.right = right;
	}

	override public function toCode():String {
		return '(' + this.left.toCode() + ' ' + this.type + ' ' + this.right.toCode() + ')';
	}
}

class Unary extends Operator {
	var isPostfix:Bool;

	public function new(type:String, right:Expression, isPostfix:Bool = false) {
		super(type, null, right);
		this.isPostfix = isPostfix;
	}

	override public function toCode():String {
		if (this.isPostfix) {
			return '(' + this.right.toCode() + ' ' + this.type + ')';
		} else {
			return super.toCode();
		}
	}
}

class Ternary extends Expression {
	var condition:Expression;
	var left:Expression;
	var right:Expression;

	public function new(condition:Expression, left:Expression, right:Expression) {
		this.condition = condition;
		this.left = left;
		this.right = right;
	}

	override public function toCode():String {
		return '(' + this.condition.toCode() + ' ? ' + this.left.toCode() + ' : ' + this.right.toCode() + ')';
	}
}

class Return extends Expression {
	var expression:Expression;

	public function new(expression:Expression) {
		this.expression = expression;
	}

	override public function toCode():String {
		return 'return ' + this.expression.toCode() + ';';
	}
}

class Scope {
	var body:Array<Expression>;

	public function new() {
		this.body = [];
	}
}

class Program extends Scope {
	override public function toCode():String {
		var code = '';
		for (expression in this.body) {
			code += expression.toCode() + '\n';
		}
		return code;
	}
}

class FunctionDeclaration extends Scope {
	var type:String;
	var name:String;
	var params:Array<FunctionParameter>;

	public function new(type:String, name:String, params:Array<FunctionParameter>) {
		this.type = type;
		this.name = name;
		this.params = params;
	}

	override public function toCode():String {
		var code = this.type + ' ' + this.name + '(';
		for (param in this.params) {
			code += param.toCode() + ', ';
		}
		code = code.slice(0, -2) + ')';
		for (expression in this.body) {
			code += expression.toCode() + '\n';
		}
		return code;
	}
}

class FunctionParameter {
	var type:String;
	var name:String;
	var qualifier:String?;
	var immutable:Bool;

	public function new(type:String, name:String, qualifier:String?, immutable:Bool) {
		this.type = type;
		this.name = name;
		this.qualifier = qualifier;
		this.immutable = immutable;
	}

	public function toCode():String {
		var code = '';
		if (this.qualifier != null) {
			code += this.qualifier + ' ';
		}
		if (this.immutable) {
			code += 'const ';
		}
		code += this.type + ' ' + this.name;
		return code;
	}
}

class VariableDeclaration extends Expression {
	var type:String;
	var name:String;
	var init:Expression?;
	var next:VariableDeclaration?;
	var immutable:Bool;

	public function new(type:String, name:String, init:Expression?, next:VariableDeclaration?, immutable:Bool) {
		this.type = type;
		this.name = name;
		this.init = init;
		this.next = next;
		this.immutable = immutable;
	}

	override public function toCode():String {
		var code = '';
		if (this.immutable) {
			code += 'const ';
		}
		code += this.type + ' ' + this.name;
		if (this.init != null) {
			code += ' = ' + this.init.toCode();
		}
		if (this.next != null) {
			code += ', ' + this.next.toCode();
		}
		return code + ';';
	}
}

class Uniform extends Expression {
	var type:String;
	var name:String;

	public function new(type:String, name:String) {
		this.type = type;
		this.name = name;
	}

	override public function toCode():String {
		return 'uniform ' + this.type + ' ' + this.name + ';';
	}
}

class Varying extends Expression {
	var type:String;
	var name:String;

	public function new(type:String, name:String) {
		this.type = type;
		this.name = name;
	}

	override public function toCode():String {
		return 'varying ' + this.type + ' ' + this.name + ';';
	}
}

class Conditional extends Scope {
	var elseConditional:Conditional?;

	public function new(condition:Expression) {
		this.body.push(condition);
	}

	override public function toCode():String {
		var code = 'if (' + this.body[0].toCode() + ')';
		code += ' {\n';
		for (i in 1...this.body.length) {
			code += this.body[i].toCode() + '\n';
		}
		code += '}';
		if (this.elseConditional != null) {
			code += ' else ' + this.elseConditional.toCode();
		}
		return code;
	}
}

class For extends Scope {
	var initialization:Expression;
	var condition:Expression;
	var afterthought:Expression;

	public function new(initialization:Expression, condition:Expression, afterthought:Expression) {
		this.initialization = initialization;
		this.condition = condition;
		this.afterthought = afterthought;
	}

	override public function toCode():String {
		return 'for (' + this.initialization.toCode() + '; ' + this.condition.toCode() + '; ' + this.afterthought.toCode() + ') {\n' + super.toCode() + '}';
	}
}

class FunctionCall extends Expression {
	var name:String;
	var params:Array<Expression>;

	public function new(name:String, params:Array<Expression>) {
		this.name = name;
		this.params = params;
	}

	override public function toCode():String {
		var code = this.name + '(';
		for (param in this.params) {
			code += param.toCode() + ', ';
		}
		return code.slice(0, -2) + ')';
	}
}

class UnaryOperators {
	static var operators = ['+', '-', '~', '!', '++', '--'];
}

class PrecedenceOperators {
	static var operators = [
		'*', '/', '%',
		'-', '+',
		'<<', '>>',
		'<', '>', '<=', '>=',
		'==', '!=',
		'&',
		'^',
		'|',
		'&&',
		'^^',
		'||',
		'?',
		'=',
		'+=', '-=', '*=', '/=', '%=', '^=', '&=', '|=', '<<=', '>>=',
		','
	].reverse();
}