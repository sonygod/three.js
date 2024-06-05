package three.js.examples.jsm.loaders;

import chevrotain.Lexer;

class VRMLLexer {
    private var lexer:Lexer;

    public function new(tokens:Array<String>) {
        lexer = new Lexer(tokens);
    }

    public function lex(inputText:String):Dynamic {
        var lexingResult = lexer.tokenize(inputText);
        if (lexingResult.errors.length > 0) {
            trace(lexingResult.errors);
            throw "THREE.VRMLLexer: Lexing errors detected.";
        }
        return lexingResult;
    }
}