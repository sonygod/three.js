// Full source:
//
//		https://github.com/zaach/jsonlint
//
// Copyright (C) 2012 Zachary Carter
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEAL-
// INGS IN THE SOFTWARE.

// Jison generated parser
class jsonlint {
	static trace() {
	}
	static symbols_:Map<String,Int> = new Map<String,Int>({
		"error":2,
		"JSONString":3,
		"STRING":4,
		"JSONNumber":5,
		"NUMBER":6,
		"JSONNullLiteral":7,
		"NULL":8,
		"JSONBooleanLiteral":9,
		"TRUE":10,
		"FALSE":11,
		"JSONText":12,
		"JSONValue":13,
		"EOF":14,
		"JSONObject":15,
		"JSONArray":16,
		"{":17,
		"}":18,
		"JSONMemberList":19,
		"JSONMember":20,
		":":21,
		",":22,
		"[":23,
		"]":24,
		"JSONElementList":25,
		"$accept":0,
		"$end":1
	});
	static terminals_:Map<Int,String> = new Map<Int,String>({
		2:"error",
		4:"STRING",
		6:"NUMBER",
		8:"NULL",
		10:"TRUE",
		11:"FALSE",
		14:"EOF",
		17:"{",
		18:"}",
		21:":",
		22:",",
		23:"[",
		24:"]"
	});
	static productions_:Array<Array<Int>> = [
		[0,3,1],
		[5,1],
		[7,1],
		[9,1],
		[9,1],
		[12,2],
		[13,1],
		[13,1],
		[13,1],
		[13,1],
		[13,1],
		[13,1],
		[15,2],
		[15,3],
		[20,3],
		[19,1],
		[19,3],
		[16,2],
		[16,3],
		[25,1],
		[25,3]
	];
	static performAction(yytext:String,yyleng:Int,yylineno:Int,yy:Dynamic,yystate:Int,$$:Array<Dynamic>,_$:Dynamic) {
		var $0 = $$.length - 1;
		switch(yystate) {
		case 1:
			// replace escaped characters with actual character
			this.$ = yytext.replace(/\\(\\|")/g, "$1").replace(/\\n/g,'\n').replace(/\\r/g,'\r').replace(/\\t/g,'\t').replace(/\\v/g,'\v').replace(/\\f/g,'\f').replace(/\\b/g,'\b');
			break;
		case 2:
			this.$ = Std.parseFloat(yytext);
			break;
		case 3:
			this.$ = null;
			break;
		case 4:
			this.$ = true;
			break;
		case 5:
			this.$ = false;
			break;
		case 6:
			return this.$ = $$[$0-1];
			break;
		case 13:
			this.$ = new Map<String,Dynamic>();
			break;
		case 14:
			this.$ = $$[$0-1];
			break;
		case 15:
			this.$ = [$$.at(0), $$.at(1)];
			break;
		case 16:
			this.$ = new Map<String,Dynamic>();
			this.$[$$[$0].at(0)] = $$[$0].at(1);
			break;
		case 17:
			this.$ = $$[$0-2];
			this.$[$$[$0].at(0)] = $$[$0].at(1);
			break;
		case 18:
			this.$ = new Array<Dynamic>();
			break;
		case 19:
			this.$ = $$[$0-1];
			break;
		case 20:
			this.$ = new Array<Dynamic>().push($$.at(0));
			break;
		case 21:
			this.$ = $$[$0-2];
			this.$ = this.$.push($$.at(0));
			break;
		}
	}
	static table:Array<Array<Dynamic>> = [
		[
			{3:5,4:[1,12],5:6,6:[1,13],7:3,8:[1,9],9:4,10:[1,10],11:[1,11],12:1,13:2,15:7,16:8,17:[1,14],23:[1,15]},
			{1:[3]},
			{14:[1,16]},
			{14:[2,7],18:[2,7],22:[2,7],24:[2,7]},
			{14:[2,8],18:[2,8],22:[2,8],24:[2,8]},
			{14:[2,9],18:[2,9],22:[2,9],24:[2,9]},
			{14:[2,10],18:[2,10],22:[2,10],24:[2,10]},
			{14:[2,11],18:[2,11],22:[2,11],24:[2,11]},
			{14:[2,12],18:[2,12],22:[2,12],24:[2,12]},
			{14:[2,3],18:[2,3],22:[2,3],24:[2,3]},
			{14:[2,4],18:[2,4],22:[2,4],24:[2,4]},
			{14:[2,5],18:[2,5],22:[2,5],24:[2,5]},
			{14:[2,1],18:[2,1],21:[2,1],22:[2,1],24:[2,1]},
			{14:[2,2],18:[2,2],22:[2,2],24:[2,2]},
			{3:20,4:[1,12],18:[1,17],19:18,20:19},
			{3:5,4:[1,12],5:6,6:[1,13],7:3,8:[1,9],9:4,10:[1,10],11:[1,11],13:23,15:7,16:8,17:[1,14],23:[1,15],24:[1,21],25:22},
			{1:[2,6]},
			{14:[2,13],18:[2,13],22:[2,13],24:[2,13]},
			{18:[1,24],22:[1,25]},
			{18:[2,16],22:[2,16]},
			{21:[1,26]},
			{14:[2,18],18:[2,18],22:[2,18],24:[2,18]},
			{22:[1,28],24:[1,27]},
			{22:[2,20],24:[2,20]},
			{14:[2,14],18:[2,14],22:[2,14],24:[2,14]},
			{3:20,4:[1,12],20:29},
			{3:5,4:[1,12],5:6,6:[1,13],7:3,8:[1,9],9:4,10:[1,10],11:[1,11],13:30,15:7,16:8,17:[1,14],23:[1,15]},
			{14:[2,19],18:[2,19],22:[2,19],24:[2,19]},
			{3:5,4:[1,12],5:6,6:[1,13],7:3,8:[1,9],9:4,10:[1,10],11:[1,11],13:31,15:7,16:8,17:[1,14],23:[1,15]},
			{18:[2,17],22:[2,17]},
			{18:[2,15],22:[2,15]},
			{22:[2,21],24:[2,21]}
		]
	];
	static defaultActions:Map<Int,Int> = new Map<Int,Int>({
		16:[2,6]
	});
	static parseError(str:String, hash:Dynamic) {
		throw new Error(str);
	}
	static parse(input:String) {
		var self = this;
		var stack:Array<Int> = [0];
		var vstack:Array<Dynamic> = [null];
		var lstack:Array<Dynamic> = [];
		var table = this.table;
		var yytext = "";
		var yylineno = 0;
		var yyleng = 0;
		var recovering = 0;
		var TERROR = 2;
		var EOF = 1;
		this.lexer.setInput(input);
		this.lexer.yy = this.yy;
		this.yy.lexer = this.lexer;
		var yyloc = this.lexer.yylloc;
		lstack.push(yyloc);
		var parseError = this.parseError;
		function popStack(n:Int) {
			stack.splice(stack.length - (n * 2));
			vstack.splice(vstack.length - n);
			lstack.splice(lstack.length - n);
		}
		function lex() {
			var token = self.lexer.lex();
			if (token == null) {
				token = 1;
			}
			if (typeof token != "number") {
				token = self.symbols_.get(token);
				if (token == null) {
					token = Std.parseInt(token);
				}
			}
			return token;
		}
		var symbol,preErrorSymbol,state,action,r,yyval = {},p,len,newState,expected;
		while(true) {
			state = stack.at(stack.length - 1);
			if (this.defaultActions.get(state) != null) {
				action = this.defaultActions.get(state);
			} else {
				if (symbol == null) {
					symbol = lex();
				}
				action = table.at(state).get(symbol);
			}
			if (action == null || action.length == 0 || action.at(0) == null) {
				if (recovering == 0) {
					expected = new Array<String>();
					for (p in table.at(state)) {
						if (this.terminals_.get(Std.parseInt(p)) != null && Std.parseInt(p) > 2) {
							expected.push("'" + this.terminals_.get(Std.parseInt(p)) + "'");
						}
					}
					var errStr = "";
					if (this.lexer.showPosition != null) {
						errStr = "Parse error on line " + (yylineno + 1) + ":\n" + this.lexer.showPosition() + "\nExpecting " + expected.join(", ") + ", got '" + this.terminals_.get(symbol) + "'";
					} else {
						errStr = "Parse error on line " + (yylineno + 1) + ": Unexpected " + (symbol == 1 ? "end of input" : ("'" + (this.terminals_.get(symbol) != null ? this.terminals_.get(symbol) : symbol) + "'"));
					}
					parseError(errStr, {text: this.lexer.match, token: this.terminals_.get(symbol) != null ? this.terminals_.get(symbol) : symbol, line: this.lexer.yylineno, loc: yyloc, expected: expected});
				}
				if (recovering == 3) {
					if (symbol == EOF) {
						throw new Error(errStr != null ? errStr : "Parsing halted.");
					}
					yyleng = this.lexer.yyleng;
					yytext = this.lexer.yytext;
					yylineno = this.lexer.yylineno;
					yyloc = this.lexer.yylloc;
					symbol = lex();
				}
				while(true) {
					if (table.at(state).get(TERROR.toString()) != null) {
						break;
					}
					if (state == 0) {
						throw new Error(errStr != null ? errStr : "Parsing halted.");
					}
					popStack(1);
					state = stack.at(stack.length - 1);
				}
				preErrorSymbol = symbol;
				symbol = TERROR;
				state = stack.at(stack.length - 1);
				action = table.at(state).get(TERROR);
				recovering = 3;
			}
			if (action.at(0) instanceof Array && action.length > 1) {
				throw new Error("Parse Error: multiple actions possible at state: " + state + ", token: " + symbol);
			}
			switch(action.at(0)) {
			case 1:
				stack.push(symbol);
				vstack.push(this.lexer.yytext);
				lstack.push(this.lexer.yylloc);
				stack.push(action.at(1));
				symbol = null;
				if (preErrorSymbol == null) {
					yyleng = this.lexer.yyleng;
					yytext = this.lexer.yytext;
					yylineno = this.lexer.yylineno;
					yyloc = this.lexer.yylloc;
					if (recovering > 0) {
						recovering--;
					}
				} else {
					symbol = preErrorSymbol;
					preErrorSymbol = null;
				}
				break;
			case 2:
				len = this.productions_.at(action.at(1)).at(1);
				yyval.$ = vstack.at(vstack.length - len);
				yyval._$ = {
					first_line:lstack.at(lstack.length - (len != null ? len : 1)).first_line,
					last_line:lstack.at(lstack.length - 1).last_line,
					first_column:lstack.at(lstack.length - (len != null ? len : 1)).first_column,
					last_column:lstack.at(lstack.length - 1).last_column
				};
				r = this.performAction.call(yyval, yytext, yyleng, yylineno, this.yy, action.at(1), vstack, lstack);
				if (r != null) {
					return r;
				}
				if (len != null) {
					stack.splice(stack.length - (len * 2));
					vstack.splice(vstack.length - len);
					lstack.splice(lstack.length - len);
				}
				stack.push(this.productions_.at(action.at(1)).at(0));
				vstack.push(yyval.$);
				lstack.push(yyval._$);
				newState = table.at(stack.at(stack.length - 2)).get(stack.at(stack.length - 1));
				stack.push(newState);
				break;
			case 3:
				return true;
			}
		}
	}
	static lexer:Lexer;
	static yy:Dynamic = {};
}
class Lexer {
	EOF:Int = 1;
	_input:String = "";
	_more:Bool = false;
	_less:Bool = false;
	done:Bool = false;
	yylineno:Int = 0;
	yyleng:Int = 0;
	yytext:String = "";
	matched:String = "";
	match:String = "";
	conditionStack:Array<String> = ["INITIAL"];
	yylloc:{first_line:Int,first_column:Int,last_line:Int,last_column:Int} = {first_line:1,first_column:0,last_line:1,last_column:0};
	options:Dynamic = {};
	parseError(str:String, hash:Dynamic) {
		if (this.yy.parseError != null) {
			this.yy.parseError(str, hash);
		} else {
			throw new Error(str);
		}
	}
	setInput(input:String) {
		this._input = input;
		this._more = this._less = this.done = false;
		this.yylineno = this.yyleng = 0;
		this.yytext = this.matched = this.match = "";
		this.conditionStack = ["INITIAL"];
		this.yylloc = {first_line:1,first_column:0,last_line:1,last_column:0};
		return this;
	}
	input() {
		var ch = this._input.charAt(0);
		this.yytext += ch;
		this.yyleng++;
		this.match += ch;
		this.matched += ch;
		var lines = ch.match(/\n/);
		if (lines != null) {
			this.yylineno++;
		}
		this._input = this._input.substring(1);
		return ch;
	}
	unput(ch:String) {
		this._input = ch + this._input;
		return this;
	}
	more() {
		this._more = true;
		return this;
	}
	less(n:Int) {
		this._input = this.match.substring(n) + this._input;
	}
	pastInput() {
		var past = this.matched.substring(0, this.matched.length - this.match.length);
		return (past.length > 20 ? "..." : "") + past.substring(past.length - 20).replace(/\n/g, "");
	}
	upcomingInput() {
		var next = this.match;
		if (next.length < 20) {
			next += this._input.substring(0, 20 - next.length);
		}
		return (next.substring(0,20) + (next.length > 20 ? "..." : "")).replace(/\n/g, "");
	}
	showPosition() {
		var pre = this.pastInput();
		var c = new Array(pre.length + 1).join("-");
		return pre + this.upcomingInput() + "\n" + c + "^";
	}
	next() {
		if (this.done) {
			return this.EOF;
		}
		if (this._input == "") {
			this.done = true;
		}
		var token,match,tempMatch,index,lines;
		if (!this._more) {
			this.yytext = "";
			this.match = "";
		}
		var rules = this._currentRules();
		for (var i = 0; i < rules.length; i++) {
			tempMatch = this._input.match(this.rules.at(rules.at(i)));
			if (tempMatch != null && (match == null || tempMatch.at(0).length > match.at(0).length)) {
				match = tempMatch;
				index = i;
				if (!this.options.flex) {
					break;
				}
			}
		}
		if (match != null) {
			lines = match.at(0).match(/\n.*/g);
			if (lines != null) {
				this.yylineno += lines.length;
			}
			this.yylloc = {first_line:this.yylloc.last_line,last_line:this.yylineno + 1,first_column:this.yylloc.last_column,last_column:lines != null ? lines.at(lines.length - 1).length - 1 : this.yylloc.last_column + match.at(0).length};
			this.yytext += match.at(0);
			this.match += match.at(0);
			this.yyleng = this.yytext.length;
			this._more = false;
			this._input = this._input.substring(match.at(0).length);
			this.matched += match.at(0);
			token = this.performAction.call(this, this.yy, this, rules.at(index), this.conditionStack.at(this.conditionStack.length - 1));
			if (this.done && this._input != "") {
				this.done = false;
			}
			if (token != null) {
				return token;
			} else {
				return null;
			}
		}
		if (this._input == "") {
			return this.EOF;
		} else {
			this.parseError("Lexical error on line " + (this.yylineno + 1) + ". Unrecognized text.\n" + this.showPosition(), {text: "", token: null, line: this.yylineno});
		}
	}
	lex() {
		var r = this.next();
		if (r != null) {
			return r;
		} else {
			return this.lex();
		}
	}
	begin(condition:String) {
		this.conditionStack.push(condition);
	}
	popState() {
		return this.conditionStack.pop();
	}
	_currentRules() {
		return this.conditions.get(this.conditionStack.at(this.conditionStack.length - 1)).rules;
	}
	topState() {
		return this.conditionStack.at(this.conditionStack.length - 2);
	}
	pushState(condition:String) {
		this.begin(condition);
	}
	performAction(yy:Dynamic,yy_:Dynamic,$avoiding_name_collisions:Int) {
		switch($avoiding_name_collisions) {
		case 0:
			// skip whitespace
			break;
		case 1:
			return 6;
			break;
		case 2:
			yy_.yytext = yy_.yytext.substring(1, yy_.yyleng - 2);
			return 4;
			break;
		case 3:
			return 17;
			break;
		case 4:
			return 18;
			break;
		case 5:
			return 23;
			break;
		case 6:
			return 24;
			break;
		case 7:
			return 22;
			break;
		case 8:
			return 21;
			break;
		case 9:
			return 10;
			break;
		case 10:
			return 11;
			break;
		case 11:
			return 8;
			break;
		case 12:
			return 14;
			break;
		case 13:
			return "INVALID";
			break;
		}
	}
	rules:Array<EReg> = [
		/^(?:\s+)/,
		/^(?:(-?([0-9]|[1-9][0-9]+))(\.[0-9]+)?([eE][-+]?[0-9]+)?\b)/,
		/^(?:"(?:\\[\\"bfnrt/]|\\u[a-fA-F0-9]{4}|[^\\\0-\x09\x0a-\x1f"])*")/,
		/^(?:\{)/,
		/^(?:\})/,
		/^(?:\[)/,
		/^(?:\])/,
		/^(?:,)/,
		/^(?::)/,
		/^(?:true\b)/,
		/^(?:false\b)/,
		/^(?:null\b)/,
		/^(?:$)/,
		/^(?:.)/
	];
	conditions:Map<String,Dynamic> = new Map<String,Dynamic>({
		"INITIAL":{rules:[0,1,2,3,4,5,6,7,8,9,10,11,12,13],inclusive:true}
	});
}
jsonlint.lexer = new Lexer();