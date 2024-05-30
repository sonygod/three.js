class VRMLLexer {
	public var lexer: Lexer;

	public function new(tokens: Array<TokenConfig>) {
		lexer = Lexer.fromConfig({ tokens: tokens });
	}

	public function lex(inputText: String): LexingResult {
		var lexingResult = lexer.tokenize(inputText);
		if (lexingResult.errors.length > 0) {
			trace(lexingResult.errors);
			throw haxe.Exception.thrown("VRMLLexer: Lexing errors detected.");
		}
		return lexingResult;
	}
}

class TokenConfig {
	public var pattern: Dynamic;
	public var categories: Array<String>;
}

class Lexer {
	public static function fromConfig(config: { tokens: Array<TokenConfig> }): Lexer {
		// implementation omitted
	}

	public function tokenize(input: String): LexingResult {
		// implementation omitted
	}
}

class LexingResult {
	public var errors: Array<String>;
}