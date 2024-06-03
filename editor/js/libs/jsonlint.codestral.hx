import js.Browser.document;
import js.JSON;

class JsonLint {
    public static function main(args: Array<String>) {
        if(args.length < 2)
            throw new Error('Usage: ' + args[0] + ' FILE');

        var source = js.FileReader.readAsText(args[1]);
        parse(source);
    }

    public static function parse(input: String): dynamic {
        var parser = new JsonParser();
        parser.setInput(input);
        return parser.parse();
    }
}

class JsonParser {
    private var lexer: JsonLexer;
    private var stack: Array<dynamic>;
    private var vstack: Array<dynamic>;
    private var lstack: Array<dynamic>;
    private var table: Array<Array<dynamic>>;
    private var defaultActions: Array<dynamic>;
    private var symbols_: Map<String, Int>;
    private var terminals_: Map<Int, String>;
    private var productions_: Array<Array<dynamic>>;
    private var yy: dynamic;
    private var yytext: String;
    private var yylineno: Int;
    private var yyleng: Int;
    private var recovering: Int;
    private var TERROR: Int;
    private var EOF: Int;

    public function new() {
        lexer = new JsonLexer();
        stack = [0];
        vstack = [null];
        lstack = [];
        table = [
            // ... table data ...
        ];
        defaultActions = [
            // ... default actions ...
        ];
        symbols_ = new Map<String, Int>();
        terminals_ = new Map<Int, String>();
        productions_ = [
            // ... productions ...
        ];
        yy = {};
        yytext = '';
        yylineno = 0;
        yyleng = 0;
        recovering = 0;
        TERROR = 2;
        EOF = 1;
    }

    public function setInput(input: String) {
        lexer.setInput(input);
        lexer.yy = yy;
        yy.lexer = lexer;
        if (Std.isOfType(lexer.yylloc, Dynamic))
            lexer.yylloc = {};
        var yyloc = lexer.yylloc;
        lstack.push(yyloc);
    }

    public function parse(): dynamic {
        // ... parse function ...
    }

    private function performAction(yytext: String, yyleng: Int, yylineno: Int, yy: dynamic, yystate: Int, $: Array<dynamic>, _: Array<dynamic>): dynamic {
        // ... performAction function ...
    }

    private function parseError(str: String, hash: Map<String, dynamic>) {
        throw new Error(str);
    }
}

class JsonLexer {
    private var EOF: Int;
    private var _input: String;
    private var _more: Bool;
    private var _less: Bool;
    private var done: Bool;
    private var yylineno: Int;
    private var yyleng: Int;
    private var yytext: String;
    private var matched: String;
    private var match: String;
    private var conditionStack: Array<String>;
    private var yylloc: dynamic;
    private var options: Map<String, dynamic>;
    private var rules: Array<ERegExp>;
    private var conditions: Map<String, dynamic>;

    public function new() {
        EOF = 1;
        _input = '';
        _more = _less = done = false;
        yylineno = yyleng = 0;
        yytext = matched = match = '';
        conditionStack = ['INITIAL'];
        yylloc = {first_line:1, first_column:0, last_line:1, last_column:0};
        options = new Map<String, dynamic>();
        rules = [
            // ... rules data ...
        ];
        conditions = new Map<String, dynamic>({
            // ... conditions data ...
        });
    }

    public function setInput(input: String): JsonLexer {
        // ... setInput function ...
    }

    // ... other lexer functions ...

    private function performAction(yy: dynamic, yy_: JsonLexer, $avoiding_name_collisions: Int): dynamic {
        // ... performAction function ...
    }
}