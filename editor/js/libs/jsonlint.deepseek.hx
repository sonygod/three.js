class JsonLint {
    static var parser:JsonLint;
    static var lexer:Lexer;

    static function main(args:Array<String>) {
        var source = sys.io.File.getContent(args[1]);
        var result = JsonLint.parse(source);
        return result;
    }

    static function parse(input:String):Dynamic {
        var self = parser;
        var stack = [0];
        var vstack = [null];
        var lstack = [];
        var table = self.table;
        var yytext = '';
        var yylineno = 0;
        var yyleng = 0;
        var recovering = 0;
        var TERROR = 2;
        var EOF = 1;

        function popStack(n:Int) {
            stack.length = stack.length - 2*n;
            vstack.length = vstack.length - n;
            lstack.length = lstack.length - n;
        }

        function lex():Int {
            var token = self.lexer.lex() || 1;
            if (typeof token !== 'number') {
                token = self.symbols_[token] || token;
            }
            return token;
        }

        var symbol:Int;
        var preErrorSymbol:Int;
        var state:Int;
        var action:Array<Int>;
        var r:Dynamic;
        var yyval:Dynamic;
        var p:Int;
        var len:Int;
        var newState:Int;
        var expected:Array<String>;

        while (true) {
            state = stack[stack.length-1];
            if (this.defaultActions[state]) {
                action = this.defaultActions[state];
            } else {
                if (symbol == null)
                    symbol = lex();
                action = table[state] && table[state][symbol];
            }

            if (typeof action === 'undefined' || !action.length || !action[0]) {
                if (!recovering) {
                    var errStr = '';
                    if (self.lexer.showPosition) {
                        errStr = 'Parse error on line '+(yylineno+1)+":\n"+self.lexer.showPosition()+"\nExpecting "+expected.join(', ') + ", got '" + self.terminals_[symbol]+ "'";
                    } else {
                        errStr = 'Parse error on line '+(yylineno+1)+": Unexpected " +
                                  (symbol == 1 /*EOF*/ ? "end of input" :
                                              ("'"+(self.terminals_[symbol] || symbol)+"'"));
                    }
                    self.parseError(errStr,
                        {text: self.lexer.match, token: self.terminals_[symbol] || symbol, line: self.lexer.yylineno, loc: yyloc, expected: expected});
                }
                if (recovering == 3) {
                    if (symbol == EOF) {
                        throw new Error(errStr || 'Parsing halted.');
                    }
                    yyleng = self.lexer.yyleng;
                    yytext = self.lexer.yytext;
                    yylineno = self.lexer.yylineno;
                    yyloc = self.lexer.yylloc;
                    symbol = lex();
                }
                while (1) {
                    if ((TERROR.toString()) in table[state]) {
                        break;
                    }
                    if (state == 0) {
                        throw new Error(errStr || 'Parsing halted.');
                    }
                    popStack(1);
                    state = stack[stack.length-1];
                }
                preErrorSymbol = symbol;
                symbol = TERROR;
                state = stack[stack.length-1];
                action = table[state] && table[state][TERROR];
                recovering = 3;
            }

            if (action[0] instanceof Array && action.length > 1) {
                throw new Error('Parse Error: multiple actions possible at state: '+state+', token: '+symbol);
            }

            switch (action[0]) {
                case 1: // shift
                    stack.push(symbol);
                    vstack.push(self.lexer.yytext);
                    lstack.push(self.lexer.yylloc);
                    stack.push(action[1]);
                    symbol = null;
                    if (!preErrorSymbol) {
                        yyleng = self.lexer.yyleng;
                        yytext = self.lexer.yytext;
                        yylineno = self.lexer.yylineno;
                        yyloc = self.lexer.yylloc;
                        if (recovering > 0)
                            recovering--;
                    } else {
                        symbol = preErrorSymbol;
                        preErrorSymbol = null;
                    }
                    break;

                case 2: // reduce
                    len = self.productions_[action[1]][1];
                    yyval = {};
                    yyval._$ = {
                        first_line: lstack[lstack.length-(len||1)].first_line,
                        last_line: lstack[lstack.length-1].last_line,
                        first_column: lstack[lstack.length-(len||1)].first_column,
                        last_column: lstack[lstack.length-1].last_column
                    };
                    r = self.performAction.call(yyval, yytext, yyleng, yylineno, self.yy, action[1], vstack, lstack);
                    if (typeof r !== 'undefined') {
                        return r;
                    }
                    if (len) {
                        stack = stack.slice(0,-1*len*2);
                        vstack = vstack.slice(0, -1*len);
                        lstack = lstack.slice(0, -1*len);
                    }
                    stack.push(self.productions_[action[1]][0]);
                    vstack.push(yyval.$);
                    lstack.push(yyval._$);
                    newState = table[stack[stack.length-2]][stack[stack.length-1]];
                    stack.push(newState);
                    break;

                case 3: // accept
                    return true;
            }
        }
    }
}