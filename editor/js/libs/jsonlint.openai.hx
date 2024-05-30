package jsonlint;

import haxe.ds.StringMap;

class JSONParser {
    public var yy:Dynamic;
    public var lexer:Lexer;

    public function new() {
        yy = {};
        yy.symbols_ = new StringMap<String>();
        yy.terminals_ = new StringMap<String>();
        yy.productions_ = [];
        yy.table = [];
        yy.defaultActions = new StringMap<Dynamic>();

        lexer = new Lexer();
        lexer.options = {};
        lexer.performAction = performAction;
    }

    public function parse(input:String):Dynamic {
        // implementation of the parser logic
        // ...
        return null;
    }

    private function performAction(yy:Dynamic, yy_:Dynamic, _$:Int):Dynamic {
        switch (_$) {
            case 0: // skip whitespace
                break;
            case 1:
                return 6;
            case 2:
                yy_.yytext = yy_.yytext.substr(1, yy_.yyleng - 2);
                return 4;
            case 3:
                return 17;
            case 4:
                return 18;
            case 5:
                return 23;
            case 6:
                return 24;
            case 7:
                return 22;
            case 8:
                return 21;
            case 9:
                return 10;
            case 10:
                return 11;
            case 11:
                return 8;
            case 12:
                return 14;
            case 13:
                return 'INVALID';
        }
        return null;
    }
}

class Lexer {
    public var yy:Dynamic;
    public var options:Dynamic;
    public var rules:Array<EReg>;

    public function new() {
        yy = {};
        options = {};
        rules = [
            ~/^(?:\s+)/,
            ~/^(?:(-?([0-9]|[1-9][0-9]+))(\.[0-9]+)?([eE][-+]?[0-9]+)?\b/,
            ~/^(?:"(?:\\[\\"bfnrt/]|\\u[a-fA-F0-9]{4}|[^\\\0-\x09\x0a-\x1f"])*")/,
            ~/^(?:\{)/,
            ~/^(?:\})/,
            ~/^(?:\[)/,
            ~/^(?:\])/,
            ~/^(?:,)/,
            ~/^(?::)/,
            ~/^(?:true\b)/,
            ~/^(?:false\b)/,
            ~/^(?:null\b)/,
            ~/^(?:$)/,
            ~/^(?:.)/,
        ];
    }

    public function lex():Int {
        // implementation of the lexer logic
        // ...
        return 0;
    }

    public function setInput(input:String):Void {
        // implementation of the lexer input logic
        // ...
    }
}