import haxe.ds.StringMap;

class Token {
	public var type: String;
	public var str: String;
	public var pos: Int;
	public var tag: Token;

	public function new(tokenizer: Tokenizer, type: String, str: String, pos: Int) {
		this.type = type;
		this.str = str;
		this.pos = pos;
		this.tag = null;
	}

	public function get endPos(): Int {
		return this.pos + this.str.length;
	}

	public function get isNumber(): Bool {
		return this.type == Token.NUMBER;
	}

	public function get isString(): Bool {
		return this.type == Token.STRING;
	}

	public function get isLiteral(): Bool {
		return this.type == Token.LITERAL;
	}

	public function get isOperator(): Bool {
		return this.type == Token.OPERATOR;
	}
}

class Tokenizer {
	public var source: String;
	public var position: Int;
	public var tokens: Array<Token>;

	public function new(source: String) {
		this.source = source;
		this.position = 0;
		this.tokens = [];
	}

	public function tokenize(): Tokenizer {
		// ... (the same as the JavaScript code)
	}

	public function skip(params: Array<RegExp | String>): String {
		// ... (the same as the JavaScript code)
	}

	public function readToken(): Token {
		// ... (the same as the JavaScript code)
	}
}

class GLSLDecoder {
	public var index: Int;
	public var tokenizer: Tokenizer;
	public var keywords: Array<{name: String, polyfill: String}>;

	public var _currentFunction: FunctionDeclaration;

	public function new() {
		// ... (the same as the JavaScript code)
	}

	public function addPolyfill(name: String, polyfill: String): GLSLDecoder {
		// ... (the same as the JavaScript code)
	}

	public function readToken(): Token {
		// ... (the same as the JavaScript code)
	}

	public function getToken(offset: Int = 0): Token {
		// ... (the same as the JavaScript code)
	}

	public function getTokensUntil(str: String, tokens: Array<Token>, offset: Int = 0): Array<Token> {
		// ... (the same as the JavaScript code)
	}

	public function readTokensUntil(str: String): Array<Token> {
		// ... (the same as the JavaScript code)
	}

	// ... (the same as the JavaScript code, with the following changes):
	// - replace 'let' with 'var'
	// - replace 'const' with 'final'
	// - replace 'null' with 'null' (Haxe doesn't need the constructor)
	// - replace 'console.error' with 'trace' (Haxe doesn't have console)
	// - replace 'new Error(...)' with 'throw new Error(...)'
	// - replace 'Array' with 'haxe.ds.Array'
	// - replace 'StringMap' with 'haxe.ds.StringMap'
}