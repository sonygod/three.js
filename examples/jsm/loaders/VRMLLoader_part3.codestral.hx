import chevrotain.Lexer;

class VRMLLexer {

    private var lexer:Lexer;

    public function new(tokens:Array<TokenConfig>) {
        this.lexer = new Lexer(tokens);
    }

    public function lex(inputText:String):LexingResult {
        var lexingResult = this.lexer.tokenize(inputText);

        if (lexingResult.errors.length > 0) {
            trace(lexingResult.errors);
            throw new Error("THREE.VRMLLexer: Lexing errors detected.");
        }

        return lexingResult;
    }
}