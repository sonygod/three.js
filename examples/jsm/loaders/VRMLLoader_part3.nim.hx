class VRMLLexer {

	var lexer:chevrotain.Lexer;

	public function new(tokens:Dynamic) {
		this.lexer = new chevrotain.Lexer(tokens);
	}

	public function lex(inputText:String) {
		var lexingResult = this.lexer.tokenize(inputText);

		if (lexingResult.errors.length > 0) {
			trace(lexingResult.errors);
			throw Error.create('THREE.VRMLLexer: Lexing errors detected.');
		}

		return lexingResult;
	}

}