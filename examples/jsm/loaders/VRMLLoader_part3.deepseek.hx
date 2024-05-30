import js.Lib;

class VRMLLexer {

    var lexer:Dynamic;

    public function new(tokens:Dynamic) {
        lexer = new js.Lib.chevrotain.Lexer(tokens);
    }

    public function lex(inputText:String):Dynamic {
        var lexingResult = lexer.tokenize(inputText);

        if (lexingResult.errors.length > 0) {
            trace(lexingResult.errors, 'THREE.VRMLLexer: Lexing errors detected.');
            throw 'THREE.VRMLLexer: Lexing errors detected.';
        }

        return lexingResult;
    }
}