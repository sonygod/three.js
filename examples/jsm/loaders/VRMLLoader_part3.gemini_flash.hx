import chevrotain.Lexer;
import chevrotain.LexerResult;

class VRMLLexer {

	public var lexer:Lexer;

	public function new(tokens:Array<Dynamic>) {
		this.lexer = new Lexer(tokens);
	}

	public function lex(inputText:String):LexerResult {
		var lexingResult:LexerResult = this.lexer.tokenize(inputText);

		if (lexingResult.errors.length > 0) {
			Sys.stderr.write(lexingResult.errors.join("\n"));
			throw "THREE.VRMLLexer: Lexing errors detected.";
		}

		return lexingResult;
	}

}