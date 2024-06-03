package;

import haxe.ds.StringMap;
import haxe.io.StringInput;

class LooseParser {
	public var toks:Tokenizer;
	public var options:ParserOptions;
	public var input:String;
	public var tok:Token;
	public var last:Token;
	public var ahead:Array<Token>;
	public var context:Array<Int>;
	public var curIndent:Int;
	public var curLineStart:Int;
	public var nextLineStart:Int;

	public function new(input:String, options:ParserOptions) {
		this.toks = new Tokenizer(new StringInput(input), options);
		this.options = this.toks.options;
		this.input = this.toks.input;
		this.tok = this.last = { type: tt.eof, start: 0, end: 0 };
		if (options.locations) this.tok.loc = new SourceLocation(this.toks, this.toks.curPosition());
		this.ahead = new Array<Token>();
		this.context = new Array<Int>();
		this.curIndent = 0;
		this.curLineStart = 0;
		this.nextLineStart = lineEnd(this.curLineStart) + 1;
	}

	public function parseTopLevel():Program {
		var node = startNodeAt(if (options.locations) {
			[0, getLineInfo(input, 0)]
		} else {
			0
		});
		node.body = new Array<Statement>();
		while (tok.type != tt.eof) node.body.push(parseStatement());
		this.last = tok;
		if (options.ecmaVersion >= 6) node.sourceType = options.sourceType;
		return finishNode(node, "Program");
	}

	public function parseStatement():Statement {
		var starttype = tok.type;
		var node = startNode();
		switch (starttype) {
		case tt._break:
		case tt._continue:
			next();
			var isBreak = starttype == tt._break;
			if (semicolon() || canInsertSemicolon()) {
				node.label = null;
			} else {
				node.label = if (tok.type == tt.name) parseIdent() else null;
				semicolon();
			}
			return finishNode(node, if (isBreak) "BreakStatement" else "ContinueStatement");
		case tt._debugger:
			next();
			semicolon();
			return finishNode(node, "DebuggerStatement");
		case tt._do:
			next();
			node.body = parseStatement();
			node.test = if (eat(tt._while)) parseParenExpression() else dummyIdent();
			semicolon();
			return finishNode(node, "DoWhileStatement");
		case tt._for:
			next();
			pushCx();
			expect(tt.parenL);
			if (tok.type == tt.semi) return parseFor(node, null);
			if (tok.type == tt._var || tok.type == tt._let || tok.type == tt._const) {
				var _init = parseVar(true);
				if (_init.declarations.length == 1 && (tok.type == tt._in || isContextual("of"))) {
					return parseForIn(node, _init);
				}
				return parseFor(node, _init);
			}
			var init = parseExpression(true);
			if (tok.type == tt._in || isContextual("of")) return parseForIn(node, toAssignable(init));
			return parseFor(node, init);
		case tt._function:
			next();
			return parseFunction(node, true);
		case tt._if:
			next();
			node.test = parseParenExpression();
			node.consequent = parseStatement();
			node.alternate = if (eat(tt._else)) parseStatement() else null;
			return finishNode(node, "IfStatement");
		case tt._return:
			next();
			if (eat(tt.semi) || canInsertSemicolon()) node.argument = null;
			else {
				node.argument = parseExpression();
				semicolon();
			}
			return finishNode(node, "ReturnStatement");
		case tt._switch:
			var blockIndent = curIndent;
			var line = curLineStart;
			next();
			node.discriminant = parseParenExpression();
			node.cases = new Array<SwitchCase>();
			pushCx();
			expect(tt.braceL);
			var cur:SwitchCase = null;
			while (!closes(tt.braceR, blockIndent, line, true)) {
				if (tok.type == tt._case || tok.type == tt._default) {
					var isCase = tok.type == tt._case;
					if (cur != null) finishNode(cur, "SwitchCase");
					node.cases.push(cur = startNode());
					cur.consequent = new Array<Statement>();
					next();
					if (isCase) cur.test = parseExpression();
					else cur.test = null;
					expect(tt.colon);
				} else {
					if (cur == null) {
						node.cases.push(cur = startNode());
						cur.consequent = new Array<Statement>();
						cur.test = null;
					}
					cur.consequent.push(parseStatement());
				}
			}
			if (cur != null) finishNode(cur, "SwitchCase");
			popCx();
			eat(tt.braceR);
			return finishNode(node, "SwitchStatement");
		case tt._throw:
			next();
			node.argument = parseExpression();
			semicolon();
			return finishNode(node, "ThrowStatement");
		case tt._try:
			next();
			node.block = parseBlock();
			node.handler = null;
			if (tok.type == tt._catch) {
				var clause = startNode();
				next();
				expect(tt.parenL);
				clause.param = toAssignable(parseExprAtom());
				expect(tt.parenR);
				clause.guard = null;
				clause.body = parseBlock();
				node.handler = finishNode(clause, "CatchClause");
			}
			node.finalizer = if (eat(tt._finally)) parseBlock() else null;
			if (node.handler == null && node.finalizer == null) return node.block;
			return finishNode(node, "TryStatement");
		case tt._var:
		case tt._let:
		case tt._const:
			return parseVar();
		case tt._while:
			next();
			node.test = parseParenExpression();
			node.body = parseStatement();
			return finishNode(node, "WhileStatement");
		case tt._with:
			next();
			node.object = parseParenExpression();
			node.body = parseStatement();
			return finishNode(node, "WithStatement");
		case tt.braceL:
			return parseBlock();
		case tt.semi:
			next();
			return finishNode(node, "EmptyStatement");
		case tt._class:
			return parseClass(true);
		case tt._import:
			return parseImport();
		case tt._export:
			return parseExport();
		default:
			var expr = parseExpression();
			if (isDummy(expr)) {
				next();
				if (tok.type == tt.eof) return finishNode(node, "EmptyStatement");
				return parseStatement();
			} else if (starttype == tt.name && expr.type == "Identifier" && eat(tt.colon)) {
				node.body = parseStatement();
				node.label = expr;
				return finishNode(node, "LabeledStatement");
			} else {
				node.expression = expr;
				semicolon();
				return finishNode(node, "ExpressionStatement");
			}
		}
	}

	public function parseBlock():BlockStatement {
		var node = startNode();
		pushCx();
		expect(tt.braceL);
		var blockIndent = curIndent;
		var line = curLineStart;
		node.body = new Array<Statement>();
		while (!closes(tt.braceR, blockIndent, line, true)) node.body.push(parseStatement());
		popCx();
		eat(tt.braceR);
		return finishNode(node, "BlockStatement");
	}

	public function parseFor(node:ForStatement, init:VariableDeclaration):ForStatement {
		node.init = init;
		node.test = null;
		node.update = null;
		if (eat(tt.semi) && tok.type != tt.semi) node.test = parseExpression();
		if (eat(tt.semi) && tok.type != tt.parenR) node.update = parseExpression();
		popCx();
		expect(tt.parenR);
		node.body = parseStatement();
		return finishNode(node, "ForStatement");
	}

	public function parseForIn(node:ForInStatement, init:VariableDeclaration):ForInStatement {
		var type = if (tok.type == tt._in) "ForInStatement" else "ForOfStatement";
		next();
		node.left = init;
		node.right = parseExpression();
		popCx();
		expect(tt.parenR);
		node.body = parseStatement();
		return finishNode(node, type);
	}

	public function parseVar(noIn:Bool):VariableDeclaration {
		var node = startNode();
		node.kind = tok.type.keyword;
		next();
		node.declarations = new Array<VariableDeclarator>();
		do {
			var decl = startNode();
			decl.id = if (options.ecmaVersion >= 6) toAssignable(parseExprAtom()) else parseIdent();
			decl.init = if (eat(tt.eq)) parseMaybeAssign(noIn) else null;
			node.declarations.push(finishNode(decl, "VariableDeclarator"));
		} while (eat(tt.comma));
		if (node.declarations.length == 0) {
			var decl = startNode();
			decl.id = dummyIdent();
			node.declarations.push(finishNode(decl, "VariableDeclarator"));
		}
		if (!noIn) semicolon();
		return finishNode(node, "VariableDeclaration");
	}

	public function parseClass(isStatement:Bool):ClassDeclaration {
		var node = startNode();
		next();
		if (tok.type == tt.name) node.id = parseIdent();
		else if (isStatement) node.id = dummyIdent();
		else node.id = null;
		node.superClass = if (eat(tt._extends)) parseExpression() else null;
		node.body = startNode();
		node.body.body = new Array<MethodDefinition>();
		pushCx();
		var indent = curIndent + 1;
		var line = curLineStart;
		eat(tt.braceL);
		if (curIndent + 1 < indent) {
			indent = curIndent;
			line = curLineStart;
		}
		while (!closes(tt.braceR, indent, line)) {
			if (semicolon()) continue;
			var method = startNode();
			var isGenerator:Bool = false;
			var start:Array<Int> = null;
			if (options.ecmaVersion >= 6) {
				method["static"] = false;
				isGenerator = eat(tt.star);
			}
			parsePropertyName(method);
			if (isDummy(method.key)) {
				if (isDummy(parseMaybeAssign())) next();
				eat(tt.comma);
				continue;
			}
			if (method.key.type == "Identifier" && !method.computed && method.key.name == "static" && (tok.type != tt.parenL && tok.type != tt.braceL)) {
				method["static"] = true;
				isGenerator = eat(tt.star);
				parsePropertyName(method);
			} else {
				method["static"] = false;
			}
			if (options.ecmaVersion >= 5 && method.key.type == "Identifier" && !method.computed && (method.key.name == "get" || method.key.name == "set") && tok.type != tt.parenL && tok.type != tt.braceL) {
				method.kind = method.key.name;
				parsePropertyName(method);
				method.value = parseMethod(false);
			} else {
				if (!method.computed && !method["static"] && !isGenerator && (method.key.type == "Identifier" && method.key.name == "constructor" || method.key.type == "Literal" && method.key.value == "constructor")) {
					method.kind = "constructor";
				} else {
					method.kind = "method";
				}
				method.value = parseMethod(isGenerator);
			}
			node.body.body.push(finishNode(method, "MethodDefinition"));
		}
		popCx();
		if (!eat(tt.braceR)) {
			this.last.end = this.tok.start;
			if (options.locations) this.last.loc.end = this.tok.loc.start;
		}
		semicolon();
		finishNode(node.body, "ClassBody");
		return finishNode(node, if (isStatement) "ClassDeclaration" else "ClassExpression");
	}

	public function parseFunction(node:FunctionDeclaration, isStatement:Bool):FunctionDeclaration {
		initFunction(node);
		if (options.ecmaVersion >= 6) node.generator = eat(tt.star);
		if (tok.type == tt.name) node.id = parseIdent();
		else if (isStatement) node.id = dummyIdent();
		node.params = parseFunctionParams();
		node.body = parseBlock();
		return finishNode(node, if (isStatement) "FunctionDeclaration" else "FunctionExpression");
	}

	public function parseExport():ExportDeclaration {
		var node = startNode();
		next();
		if (eat(tt.star)) {
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			return finishNode(node, "ExportAllDeclaration");
		}
		if (eat(tt._default)) {
			var expr = parseMaybeAssign();
			if (expr.id != null) {
				switch (expr.type) {
				case "FunctionExpression":
					expr.type = "FunctionDeclaration";
					break;
				case "ClassExpression":
					expr.type = "ClassDeclaration";
					break;
				}
			}
			node.declaration = expr;
			semicolon();
			return finishNode(node, "ExportDefaultDeclaration");
		}
		if (tok.type.keyword) {
			node.declaration = parseStatement();
			node.specifiers = new Array<ExportSpecifier>();
			node.source = null;
		} else {
			node.declaration = null;
			node.specifiers = parseExportSpecifierList();
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			semicolon();
		}
		return finishNode(node, "ExportNamedDeclaration");
	}

	public function parseImport():ImportDeclaration {
		var node = startNode();
		next();
		if (tok.type == tt.string) {
			node.specifiers = new Array<ImportSpecifier>();
			node.source = parseExprAtom();
			node.kind = "";
		} else {
			var elt:ImportSpecifier = null;
			if (tok.type == tt.name && tok.value != "from") {
				elt = startNode();
				elt.local = parseIdent();
				finishNode(elt, "ImportDefaultSpecifier");
				eat(tt.comma);
			}
			node.specifiers = parseImportSpecifierList();
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			if (elt != null) node.specifiers.unshift(elt);
		}
		semicolon();
		return finishNode(node, "ImportDeclaration");
	}

	public function parseImportSpecifierList():Array<ImportSpecifier> {
		var elts = new Array<ImportSpecifier>();
		if (tok.type == tt.star) {
			var elt = startNode();
			next();
			if (eatContextual("as")) elt.local = parseIdent();
			elts.push(finishNode(elt, "ImportNamespaceSpecifier"));
		} else {
			var indent = curIndent;
			var line = curLineStart;
			var continuedLine = nextLineStart;
			pushCx();
			eat(tt.braceL);
			if (curLineStart > continuedLine) continuedLine = curLineStart;
			while (!closes(tt.braceR, indent + (if (curLineStart <= continuedLine) 1 else 0), line)) {
				var elt = startNode();
				if (eat(tt.star)) {
					if (eatContextual("as")) elt.local = parseIdent();
					finishNode(elt, "ImportNamespaceSpecifier");
				} else {
					if (isContextual("from")) break;
					elt.imported = parseIdent();
					elt.local = if (eatContextual("as")) parseIdent() else elt.imported;
					finishNode(elt, "ImportSpecifier");
				}
				elts.push(elt);
				eat(tt.comma);
			}
			eat(tt.braceR);
			popCx();
		}
		return elts;
	}

	public function parseExportSpecifierList():Array<ExportSpecifier> {
		var elts = new Array<ExportSpecifier>();
		var indent = curIndent;
		var line = curLineStart;
		var continuedLine = nextLineStart;
		pushCx();
		eat(tt.braceL);
		if (curLineStart > continuedLine) continuedLine = curLineStart;
		while (!closes(tt.braceR, indent + (if (curLineStart <= continuedLine) 1 else 0), line)) {
			if (isContextual("from")) break;
			var elt = startNode();
			elt.local = parseIdent();
			elt.exported = if (eatContextual("as")) parseIdent() else elt.local;
			finishNode(elt, "ExportSpecifier");
			elts.push(elt);
			eat(tt.comma);
		}
		eat(tt.braceR);
		popCx();
		return elts;
	}

	public function parseExpression(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var expr = parseMaybeAssign(noIn);
		if (tok.type == tt.comma) {
			var node = startNodeAt(start);
			node.expressions = new Array<Expression>();
			node.expressions.push(expr);
			while (eat(tt.comma)) node.expressions.push(parseMaybeAssign(noIn));
			return finishNode(node, "SequenceExpression");
		}
		return expr;
	}

	public function parseParenExpression():Expression {
		pushCx();
		expect(tt.parenL);
		var val = parseExpression();
		popCx();
		expect(tt.parenR);
		return val;
	}

	public function parseMaybeAssign(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var left = parseMaybeConditional(noIn);
		if (tok.type.isAssign) {
			var node = startNodeAt(start);
			node.operator = tok.value;
			node.left = if (tok.type == tt.eq) toAssignable(left) else checkLVal(left);
			next();
			node.right = parseMaybeAssign(noIn);
			return finishNode(node, "AssignmentExpression");
		}
		return left;
	}

	public function parseMaybeConditional(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var expr = parseExprOps(noIn);
		if (eat(tt.question)) {
			var node = startNodeAt(start);
			node.test = expr;
			node.consequent = parseMaybeAssign();
			node.alternate = if (expect(tt.colon)) parseMaybeAssign(noIn) else dummyIdent();
			return finishNode(node, "ConditionalExpression");
		}
		return expr;
	}

	public function parseExprOps(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var indent = curIndent;
		var line = curLineStart;
		return parseExprOp(parseMaybeUnary(noIn), start, -1, noIn, indent, line);
	}

	public function parseExprOp(left:Expression, start:Array<Int>, minPrec:Int, noIn:Bool, indent:Int, line:Int):Expression {
		if (curLineStart != line && curIndent < indent && tokenStartsLine()) return left;
		var prec = tok.type.binop;
		if (prec != null && (!noIn || tok.type != tt._in)) {
			if (prec > minPrec) {
				var node = startNodeAt(start);
				node.left = left;
				node.operator = tok.value;
				next();
				if (curLineStart != line && curIndent < indent && tokenStartsLine()) {
					node.right = dummyIdent();
				} else {
					var rightStart = storeCurrentPos();
					node.right = parseExprOp(parseMaybeUnary(noIn), rightStart, prec, noIn, indent, line);
				}
				this.finishNode(node, if (/"&&"|"||"/.match(node.operator) != null) "LogicalExpression" else "BinaryExpression");
				return parseExprOp(node, start, minPrec, noIn, indent, line);
			}
		}
		return left;
	}

	public function parseMaybeUnary(noIn:Bool = false):Expression {
		if (tok.type.prefix) {
			var node = startNode();
			var update = tok.type == tt.incDec;
			node.operator = tok.value;
			node.prefix = true;
			next();
			node.argument = parseMaybeUnary(noIn);
			if (update) node.argument = checkLVal(node.argument);
			return finishNode(node, if (update) "UpdateExpression" else "UnaryExpression");
		} else if (tok.type == tt.ellipsis) {
			var node = startNode();
			next();
			node.argument = parseMaybeUnary(noIn);
			return finishNode(node, "SpreadElement");
		}
		var start = storeCurrentPos();
		var expr = parseExprSubscripts();
		while (tok.type.postfix && !canInsertSemicolon()) {
			var node = startNodeAt(start);
			node.operator = tok.value;
			node.prefix = false;
			node.argument = checkLVal(expr);
			next();
			expr = finishNode(node, "UpdateExpression");
		}
		return expr;
	}

	public function parseExprSubscripts():Expression {
		var start = storeCurrentPos();
		return parseSubscripts(parseExprAtom(), start, false, curIndent, curLineStart);
	}

	public function parseSubscripts(base:Expression, start:Array<Int>, noCalls:Bool, startIndent:Int, line:Int):Expression {
		while (true) {
			if (curLineStart != line && curIndent <= startIndent && tokenStartsLine()) {
				if (tok.type == tt.dot && curIndent == startIndent) --startIndent;
				else return base;
			}
			if (eat(tt.dot)) {
				var node = startNodeAt(start);
				node.object = base;
				if (curLineStart != line && curIndent <= startIndent && tokenStartsLine()) node.property = dummyIdent();
				else node.property = parsePropertyAccessor() || dummyIdent();
				node.computed = false;
				base = finishNode(node, "MemberExpression");
			} else if (tok.type == tt.bracketL) {
				pushCx();
				next();
				var node = startNodeAt(start);
				node.object = base;
				node.property = parseExpression();
				node.computed = true;
				popCx();
				expect(tt.bracketR);
				base = finishNode(node, "MemberExpression");
			} else if (!noCalls && tok.type == tt.parenL) {
				pushCx();
				var node = startNodeAt(start);
				node.callee = base;
				node.arguments = parseExprList(tt.parenR);
				base = finishNode(node, "CallExpression");
			} else if (tok.type == tt.backQuote) {
				var node = startNodeAt(start);
				node.tag = base;
				node.quasi = parseTemplate();
				base = finishNode(node, "TaggedTemplateExpression");
			} else {
				return base;
			}
		}
	}

	public function parseExprAtom():Expression {
		var node:Expression = null;
		switch (tok.type) {
		case tt._this:
		case tt._super:
			var type = if (tok.type == tt._this) "ThisExpression" else "Super";
			node = startNode();
			next();
			return finishNode(node, type);
		case tt.name:
			var start = storeCurrentPos();
			var id = parseIdent();
			return if (eat(tt.arrow)) parseArrowExpression(startNodeAt(start), [id]) else id;
		case tt.regexp:
			node = startNode();
			var val = tok.value;
			node.regex = { pattern: val.pattern, flags: val.flags };
			node.value = val.value;
			node.raw = input.substr(tok.start, tok.end);
			next();
			return finishNode(node, "Literal");
		case tt.num:
		case tt.string:
			node = startNode();
			node.value = tok.value;
			node.raw = input.substr(tok.start, tok.end);
			next();
			return finishNode(node, "Literal");
		case tt._null:
		case tt._true:
		case tt._false:
			node = startNode();
			node.value = if (tok.type == tt._null) null else if (tok.type == tt._true) true else false;
			node.raw = tok.type.keyword;
			next();
			return finishNode(node, "Literal");
		case tt.parenL:
			var parenStart = storeCurrentPos();
			next();
			var inner = parseExpression();
			expect(tt.parenR);
			if (eat(tt.arrow)) {
				return parseArrowExpression(startNodeAt(parenStart), if (inner.expressions != null) inner.expressions else if (isDummy(inner)) new Array<Expression>() else new Array<Expression>(inner));
			}
			if (options.preserveParens) {
				var par = startNodeAt(parenStart);
				par.expression = inner;
				inner = finishNode(par, "ParenthesizedExpression");
			}
			return inner;
		case tt.bracketL:
			node = startNode();
			pushCx();
			node.elements = parseExprList(tt.bracketR, true);
			return finishNode(node, "ArrayExpression");
		case tt.braceL:
			return parseObj();
		case tt._class:
			return parseClass(false);
		case tt._function:
			node = startNode();
			next();
			return parseFunction(node, false);
		case tt._new:
			return parseNew();
		case tt._yield:
			node = startNode();
			next();
			if (semicolon() || canInsertSemicolon() || (tok.type != tt.star && !tok.type.startsExpr)) {
				node.delegate = false;
				node.argument = null;
			} else {
				node.delegate = eat(tt.star);
				node.argument = parseMaybeAssign();
			}
			return finishNode(node, "YieldExpression");
		case tt.backQuote:
			return parseTemplate();
		default:
			return dummyIdent();
		}
	}

	public function parseNew():NewExpression {
		var node = startNode();
		var startIndent = curIndent;
		var line = curLineStart;
		var meta = parseIdent(true);
		if (options.ecmaVersion >= 6 && eat(tt.dot)) {
			node.meta = meta;
			node.property = parseIdent(true);
			return finishNode(node, "MetaProperty");
		}
		var start = storeCurrentPos();
		node.callee = parseSubscripts(parseExprAtom(), start, true, startIndent, line);
		if (tok.type == tt.parenL) {
			pushCx();
			node.arguments = parseExprList(tt.parenR);
		} else {
			node.arguments = new Array<Expression>();
		}
		return finishNode(node, "NewExpression");
	}

	public function parseTemplateElement():TemplateElement {
		var elem = startNode();
		elem.value = { raw: input.substr(tok.start, tok.end), cooked: tok.value };
		next();
		elem.tail = tok.type == tt.backQuote;
		return finishNode(elem, "TemplateElement");
	}

	public function parseTemplate():TemplateLiteral {
		var node = startNode();
		next();
		node.expressions = new Array<Expression>();
		var curElt = parseTemplateElement();
		node.quasis = new Array<TemplateElement>();
		node.quasis.push(curElt);
		while (!curElt.tail) {
			next();
			node.expressions.push(parseExpression());
			if (expect(tt.braceR)) {
				curElt = parseTemplateElement();
			} else {
				curElt = startNode();
				curElt.value = { cooked: "", raw: "" };
				curElt.tail = true;
			}
			node.quasis.push(curElt);
		}
		expect(tt.backQuote);
		return finishNode(node, "TemplateLiteral");
	}

	public function parseObj():ObjectExpression {
		var node = startNode();
		node.properties = new Array<Property>();
		pushCx();
		var indent = curIndent + 1;
		var line = curLineStart;
		eat(tt.braceL);
		if (curIndent + 1 < indent) {
			indent = curIndent;
			line = curLineStart;
		}
		while (!closes(tt.braceR, indent, line)) {
			var prop = startNode();
			var isGenerator:Bool = false;
			var start:Array<Int> = null;
			if (options.ecmaVersion >= 6) {
				start = storeCurrentPos();
				prop.method = false;
				prop.shorthand = false;
				isGenerator = eat(tt.star);
			}
			parsePropertyName(prop);
			if (isDummy(prop.key)) {
				if (isDummy(parseMaybeAssign())) next();
				eat(tt.comma);
				continue;
			}
			if (eat(tt.colon)) {
				prop.kind = "init";
				prop.value = parseMaybeAssign();
			} else if (options.ecmaVersion >= 6 && (tok.type == tt.parenL || tok.type == tt.braceL)) {
				prop.kind = "init";
				prop.method = true;
				prop.value = parseMethod(isGenerator);
			} else if (options.ecmaVersion >= 5 && prop.key.type == "Identifier" && !prop.computed && (prop.key.name == "get" || prop.key.name == "set") && (tok.type != tt.comma && tok.type != tt.braceR)) {
				prop.kind = prop.key.name;
				parsePropertyName(prop);
				prop.value = parseMethod(false);
			} else {
				prop.kind = "init";
				if (options.ecmaVersion >= 6) {
					if (eat(tt.eq)) {
						var assign = startNodeAt(start);
						assign.operator = "=";
						assign.left = prop.key;
						assign.right = parseMaybeAssign();
						prop.value = finishNode(assign, "AssignmentExpression");
					} else {
						prop.value = prop.key;
					}
				} else {
					prop.value = dummyIdent();
				}
				prop.shorthand = true;
			}
			node.properties.push(finishNode(prop, "Property"));
			eat(tt.comma);
		}
		popCx();
		if (!eat(tt.braceR)) {
			this.last.end = this.tok.start;
			if (options.locations) this.last.loc.end = this.tok.loc.start;
		}
		return finishNode(node, "ObjectExpression");
	}

	public function parsePropertyName(prop:Property) {
		if (options.ecmaVersion >= 6) {
			if (eat(tt.bracketL)) {
				prop.computed = true;
				prop.key = parseExpression();
				expect(tt.bracketR);
				return;
			} else {
				prop.computed = false;
			}
		}
		var key = if (tok.type == tt.num || tok.type == tt.string) parseExprAtom() else parseIdent();
		prop.key = if (key != null) key else dummyIdent();
	}

	public function parsePropertyAccessor():Expression {
		if (tok.type == tt.name || tok.type.keyword) return parseIdent();
		return null;
	}

	public function parseIdent(isMeta:Bool = false):Identifier {
		var name = if (tok.type == tt.name) tok.value else tok.type.keyword;
		if (name == null) return dummyIdent();
		var node = startNode();
		next();
		node.name = name;
		return finishNode(node, "Identifier");
	}

	public function initFunction(node:Function) {
		node.id = null;
		node.params = new Array<Pattern>();
		if (options.ecmaVersion >= 6) {
			node.generator = false;
			node.expression = false;
		}
	}

	public
package;

import haxe.ds.StringMap;
import haxe.io.StringInput;

class LooseParser {
	public var toks:Tokenizer;
	public var options:ParserOptions;
	public var input:String;
	public var tok:Token;
	public var last:Token;
	public var ahead:Array<Token>;
	public var context:Array<Int>;
	public var curIndent:Int;
	public var curLineStart:Int;
	public var nextLineStart:Int;

	public function new(input:String, options:ParserOptions) {
		this.toks = new Tokenizer(new StringInput(input), options);
		this.options = this.toks.options;
		this.input = this.toks.input;
		this.tok = this.last = { type: tt.eof, start: 0, end: 0 };
		if (options.locations) this.tok.loc = new SourceLocation(this.toks, this.toks.curPosition());
		this.ahead = new Array<Token>();
		this.context = new Array<Int>();
		this.curIndent = 0;
		this.curLineStart = 0;
		this.nextLineStart = lineEnd(this.curLineStart) + 1;
	}

	public function parseTopLevel():Program {
		var node = startNodeAt(if (options.locations) {
			[0, getLineInfo(input, 0)]
		} else {
			0
		});
		node.body = new Array<Statement>();
		while (tok.type != tt.eof) node.body.push(parseStatement());
		this.last = tok;
		if (options.ecmaVersion >= 6) node.sourceType = options.sourceType;
		return finishNode(node, "Program");
	}

	public function parseStatement():Statement {
		var starttype = tok.type;
		var node = startNode();
		switch (starttype) {
		case tt._break:
		case tt._continue:
			next();
			var isBreak = starttype == tt._break;
			if (semicolon() || canInsertSemicolon()) {
				node.label = null;
			} else {
				node.label = if (tok.type == tt.name) parseIdent() else null;
				semicolon();
			}
			return finishNode(node, if (isBreak) "BreakStatement" else "ContinueStatement");
		case tt._debugger:
			next();
			semicolon();
			return finishNode(node, "DebuggerStatement");
		case tt._do:
			next();
			node.body = parseStatement();
			node.test = if (eat(tt._while)) parseParenExpression() else dummyIdent();
			semicolon();
			return finishNode(node, "DoWhileStatement");
		case tt._for:
			next();
			pushCx();
			expect(tt.parenL);
			if (tok.type == tt.semi) return parseFor(node, null);
			if (tok.type == tt._var || tok.type == tt._let || tok.type == tt._const) {
				var _init = parseVar(true);
				if (_init.declarations.length == 1 && (tok.type == tt._in || isContextual("of"))) {
					return parseForIn(node, _init);
				}
				return parseFor(node, _init);
			}
			var init = parseExpression(true);
			if (tok.type == tt._in || isContextual("of")) return parseForIn(node, toAssignable(init));
			return parseFor(node, init);
		case tt._function:
			next();
			return parseFunction(node, true);
		case tt._if:
			next();
			node.test = parseParenExpression();
			node.consequent = parseStatement();
			node.alternate = if (eat(tt._else)) parseStatement() else null;
			return finishNode(node, "IfStatement");
		case tt._return:
			next();
			if (eat(tt.semi) || canInsertSemicolon()) node.argument = null;
			else {
				node.argument = parseExpression();
				semicolon();
			}
			return finishNode(node, "ReturnStatement");
		case tt._switch:
			var blockIndent = curIndent;
			var line = curLineStart;
			next();
			node.discriminant = parseParenExpression();
			node.cases = new Array<SwitchCase>();
			pushCx();
			expect(tt.braceL);
			var cur:SwitchCase = null;
			while (!closes(tt.braceR, blockIndent, line, true)) {
				if (tok.type == tt._case || tok.type == tt._default) {
					var isCase = tok.type == tt._case;
					if (cur != null) finishNode(cur, "SwitchCase");
					node.cases.push(cur = startNode());
					cur.consequent = new Array<Statement>();
					next();
					if (isCase) cur.test = parseExpression();
					else cur.test = null;
					expect(tt.colon);
				} else {
					if (cur == null) {
						node.cases.push(cur = startNode());
						cur.consequent = new Array<Statement>();
						cur.test = null;
					}
					cur.consequent.push(parseStatement());
				}
			}
			if (cur != null) finishNode(cur, "SwitchCase");
			popCx();
			eat(tt.braceR);
			return finishNode(node, "SwitchStatement");
		case tt._throw:
			next();
			node.argument = parseExpression();
			semicolon();
			return finishNode(node, "ThrowStatement");
		case tt._try:
			next();
			node.block = parseBlock();
			node.handler = null;
			if (tok.type == tt._catch) {
				var clause = startNode();
				next();
				expect(tt.parenL);
				clause.param = toAssignable(parseExprAtom());
				expect(tt.parenR);
				clause.guard = null;
				clause.body = parseBlock();
				node.handler = finishNode(clause, "CatchClause");
			}
			node.finalizer = if (eat(tt._finally)) parseBlock() else null;
			if (node.handler == null && node.finalizer == null) return node.block;
			return finishNode(node, "TryStatement");
		case tt._var:
		case tt._let:
		case tt._const:
			return parseVar();
		case tt._while:
			next();
			node.test = parseParenExpression();
			node.body = parseStatement();
			return finishNode(node, "WhileStatement");
		case tt._with:
			next();
			node.object = parseParenExpression();
			node.body = parseStatement();
			return finishNode(node, "WithStatement");
		case tt.braceL:
			return parseBlock();
		case tt.semi:
			next();
			return finishNode(node, "EmptyStatement");
		case tt._class:
			return parseClass(true);
		case tt._import:
			return parseImport();
		case tt._export:
			return parseExport();
		default:
			var expr = parseExpression();
			if (isDummy(expr)) {
				next();
				if (tok.type == tt.eof) return finishNode(node, "EmptyStatement");
				return parseStatement();
			} else if (starttype == tt.name && expr.type == "Identifier" && eat(tt.colon)) {
				node.body = parseStatement();
				node.label = expr;
				return finishNode(node, "LabeledStatement");
			} else {
				node.expression = expr;
				semicolon();
				return finishNode(node, "ExpressionStatement");
			}
		}
	}

	public function parseBlock():BlockStatement {
		var node = startNode();
		pushCx();
		expect(tt.braceL);
		var blockIndent = curIndent;
		var line = curLineStart;
		node.body = new Array<Statement>();
		while (!closes(tt.braceR, blockIndent, line, true)) node.body.push(parseStatement());
		popCx();
		eat(tt.braceR);
		return finishNode(node, "BlockStatement");
	}

	public function parseFor(node:ForStatement, init:VariableDeclaration):ForStatement {
		node.init = init;
		node.test = null;
		node.update = null;
		if (eat(tt.semi) && tok.type != tt.semi) node.test = parseExpression();
		if (eat(tt.semi) && tok.type != tt.parenR) node.update = parseExpression();
		popCx();
		expect(tt.parenR);
		node.body = parseStatement();
		return finishNode(node, "ForStatement");
	}

	public function parseForIn(node:ForInStatement, init:VariableDeclaration):ForInStatement {
		var type = if (tok.type == tt._in) "ForInStatement" else "ForOfStatement";
		next();
		node.left = init;
		node.right = parseExpression();
		popCx();
		expect(tt.parenR);
		node.body = parseStatement();
		return finishNode(node, type);
	}

	public function parseVar(noIn:Bool):VariableDeclaration {
		var node = startNode();
		node.kind = tok.type.keyword;
		next();
		node.declarations = new Array<VariableDeclarator>();
		do {
			var decl = startNode();
			decl.id = if (options.ecmaVersion >= 6) toAssignable(parseExprAtom()) else parseIdent();
			decl.init = if (eat(tt.eq)) parseMaybeAssign(noIn) else null;
			node.declarations.push(finishNode(decl, "VariableDeclarator"));
		} while (eat(tt.comma));
		if (node.declarations.length == 0) {
			var decl = startNode();
			decl.id = dummyIdent();
			node.declarations.push(finishNode(decl, "VariableDeclarator"));
		}
		if (!noIn) semicolon();
		return finishNode(node, "VariableDeclaration");
	}

	public function parseClass(isStatement:Bool):ClassDeclaration {
		var node = startNode();
		next();
		if (tok.type == tt.name) node.id = parseIdent();
		else if (isStatement) node.id = dummyIdent();
		else node.id = null;
		node.superClass = if (eat(tt._extends)) parseExpression() else null;
		node.body = startNode();
		node.body.body = new Array<MethodDefinition>();
		pushCx();
		var indent = curIndent + 1;
		var line = curLineStart;
		eat(tt.braceL);
		if (curIndent + 1 < indent) {
			indent = curIndent;
			line = curLineStart;
		}
		while (!closes(tt.braceR, indent, line)) {
			if (semicolon()) continue;
			var method = startNode();
			var isGenerator:Bool = false;
			var start:Array<Int> = null;
			if (options.ecmaVersion >= 6) {
				method["static"] = false;
				isGenerator = eat(tt.star);
			}
			parsePropertyName(method);
			if (isDummy(method.key)) {
				if (isDummy(parseMaybeAssign())) next();
				eat(tt.comma);
				continue;
			}
			if (method.key.type == "Identifier" && !method.computed && method.key.name == "static" && (tok.type != tt.parenL && tok.type != tt.braceL)) {
				method["static"] = true;
				isGenerator = eat(tt.star);
				parsePropertyName(method);
			} else {
				method["static"] = false;
			}
			if (options.ecmaVersion >= 5 && method.key.type == "Identifier" && !method.computed && (method.key.name == "get" || method.key.name == "set") && tok.type != tt.parenL && tok.type != tt.braceL) {
				method.kind = method.key.name;
				parsePropertyName(method);
				method.value = parseMethod(false);
			} else {
				if (!method.computed && !method["static"] && !isGenerator && (method.key.type == "Identifier" && method.key.name == "constructor" || method.key.type == "Literal" && method.key.value == "constructor")) {
					method.kind = "constructor";
				} else {
					method.kind = "method";
				}
				method.value = parseMethod(isGenerator);
			}
			node.body.body.push(finishNode(method, "MethodDefinition"));
		}
		popCx();
		if (!eat(tt.braceR)) {
			this.last.end = this.tok.start;
			if (options.locations) this.last.loc.end = this.tok.loc.start;
		}
		semicolon();
		finishNode(node.body, "ClassBody");
		return finishNode(node, if (isStatement) "ClassDeclaration" else "ClassExpression");
	}

	public function parseFunction(node:FunctionDeclaration, isStatement:Bool):FunctionDeclaration {
		initFunction(node);
		if (options.ecmaVersion >= 6) node.generator = eat(tt.star);
		if (tok.type == tt.name) node.id = parseIdent();
		else if (isStatement) node.id = dummyIdent();
		node.params = parseFunctionParams();
		node.body = parseBlock();
		return finishNode(node, if (isStatement) "FunctionDeclaration" else "FunctionExpression");
	}

	public function parseExport():ExportDeclaration {
		var node = startNode();
		next();
		if (eat(tt.star)) {
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			return finishNode(node, "ExportAllDeclaration");
		}
		if (eat(tt._default)) {
			var expr = parseMaybeAssign();
			if (expr.id != null) {
				switch (expr.type) {
				case "FunctionExpression":
					expr.type = "FunctionDeclaration";
					break;
				case "ClassExpression":
					expr.type = "ClassDeclaration";
					break;
				}
			}
			node.declaration = expr;
			semicolon();
			return finishNode(node, "ExportDefaultDeclaration");
		}
		if (tok.type.keyword) {
			node.declaration = parseStatement();
			node.specifiers = new Array<ExportSpecifier>();
			node.source = null;
		} else {
			node.declaration = null;
			node.specifiers = parseExportSpecifierList();
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			semicolon();
		}
		return finishNode(node, "ExportNamedDeclaration");
	}

	public function parseImport():ImportDeclaration {
		var node = startNode();
		next();
		if (tok.type == tt.string) {
			node.specifiers = new Array<ImportSpecifier>();
			node.source = parseExprAtom();
			node.kind = "";
		} else {
			var elt:ImportSpecifier = null;
			if (tok.type == tt.name && tok.value != "from") {
				elt = startNode();
				elt.local = parseIdent();
				finishNode(elt, "ImportDefaultSpecifier");
				eat(tt.comma);
			}
			node.specifiers = parseImportSpecifierList();
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			if (elt != null) node.specifiers.unshift(elt);
		}
		semicolon();
		return finishNode(node, "ImportDeclaration");
	}

	public function parseImportSpecifierList():Array<ImportSpecifier> {
		var elts = new Array<ImportSpecifier>();
		if (tok.type == tt.star) {
			var elt = startNode();
			next();
			if (eatContextual("as")) elt.local = parseIdent();
			elts.push(finishNode(elt, "ImportNamespaceSpecifier"));
		} else {
			var indent = curIndent;
			var line = curLineStart;
			var continuedLine = nextLineStart;
			pushCx();
			eat(tt.braceL);
			if (curLineStart > continuedLine) continuedLine = curLineStart;
			while (!closes(tt.braceR, indent + (if (curLineStart <= continuedLine) 1 else 0), line)) {
				var elt = startNode();
				if (eat(tt.star)) {
					if (eatContextual("as")) elt.local = parseIdent();
					finishNode(elt, "ImportNamespaceSpecifier");
				} else {
					if (isContextual("from")) break;
					elt.imported = parseIdent();
					elt.local = if (eatContextual("as")) parseIdent() else elt.imported;
					finishNode(elt, "ImportSpecifier");
				}
				elts.push(elt);
				eat(tt.comma);
			}
			eat(tt.braceR);
			popCx();
		}
		return elts;
	}

	public function parseExportSpecifierList():Array<ExportSpecifier> {
		var elts = new Array<ExportSpecifier>();
		var indent = curIndent;
		var line = curLineStart;
		var continuedLine = nextLineStart;
		pushCx();
		eat(tt.braceL);
		if (curLineStart > continuedLine) continuedLine = curLineStart;
		while (!closes(tt.braceR, indent + (if (curLineStart <= continuedLine) 1 else 0), line)) {
			if (isContextual("from")) break;
			var elt = startNode();
			elt.local = parseIdent();
			elt.exported = if (eatContextual("as")) parseIdent() else elt.local;
			finishNode(elt, "ExportSpecifier");
			elts.push(elt);
			eat(tt.comma);
		}
		eat(tt.braceR);
		popCx();
		return elts;
	}

	public function parseExpression(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var expr = parseMaybeAssign(noIn);
		if (tok.type == tt.comma) {
			var node = startNodeAt(start);
			node.expressions = new Array<Expression>();
			node.expressions.push(expr);
			while (eat(tt.comma)) node.expressions.push(parseMaybeAssign(noIn));
			return finishNode(node, "SequenceExpression");
		}
		return expr;
	}

	public function parseParenExpression():Expression {
		pushCx();
		expect(tt.parenL);
		var val = parseExpression();
		popCx();
		expect(tt.parenR);
		return val;
	}

	public function parseMaybeAssign(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var left = parseMaybeConditional(noIn);
		if (tok.type.isAssign) {
			var node = startNodeAt(start);
			node.operator = tok.value;
			node.left = if (tok.type == tt.eq) toAssignable(left) else checkLVal(left);
			next();
			node.right = parseMaybeAssign(noIn);
			return finishNode(node, "AssignmentExpression");
		}
		return left;
	}

	public function parseMaybeConditional(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var expr = parseExprOps(noIn);
		if (eat(tt.question)) {
			var node = startNodeAt(start);
			node.test = expr;
			node.consequent = parseMaybeAssign();
			node.alternate = if (expect(tt.colon)) parseMaybeAssign(noIn) else dummyIdent();
			return finishNode(node, "ConditionalExpression");
		}
		return expr;
	}

	public function parseExprOps(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var indent = curIndent;
		var line = curLineStart;
		return parseExprOp(parseMaybeUnary(noIn), start, -1, noIn, indent, line);
	}

	public function parseExprOp(left:Expression, start:Array<Int>, minPrec:Int, noIn:Bool, indent:Int, line:Int):Expression {
		if (curLineStart != line && curIndent < indent && tokenStartsLine()) return left;
		var prec = tok.type.binop;
		if (prec != null && (!noIn || tok.type != tt._in)) {
			if (prec > minPrec) {
				var node = startNodeAt(start);
				node.left = left;
				node.operator = tok.value;
				next();
				if (curLineStart != line && curIndent < indent && tokenStartsLine()) {
					node.right = dummyIdent();
				} else {
					var rightStart = storeCurrentPos();
					node.right = parseExprOp(parseMaybeUnary(noIn), rightStart, prec, noIn, indent, line);
				}
				this.finishNode(node, if (/"&&"|"||"/.match(node.operator) != null) "LogicalExpression" else "BinaryExpression");
				return parseExprOp(node, start, minPrec, noIn, indent, line);
			}
		}
		return left;
	}

	public function parseMaybeUnary(noIn:Bool = false):Expression {
		if (tok.type.prefix) {
			var node = startNode();
			var update = tok.type == tt.incDec;
			node.operator = tok.value;
			node.prefix = true;
			next();
			node.argument = parseMaybeUnary(noIn);
			if (update) node.argument = checkLVal(node.argument);
			return finishNode(node, if (update) "UpdateExpression" else "UnaryExpression");
		} else if (tok.type == tt.ellipsis) {
			var node = startNode();
			next();
			node.argument = parseMaybeUnary(noIn);
			return finishNode(node, "SpreadElement");
		}
		var start = storeCurrentPos();
		var expr = parseExprSubscripts();
		while (tok.type.postfix && !canInsertSemicolon()) {
			var node = startNodeAt(start);
			node.operator = tok.value;
			node.prefix = false;
			node.argument = checkLVal(expr);
			next();
			expr = finishNode(node, "UpdateExpression");
		}
		return expr;
	}

	public function parseExprSubscripts():Expression {
		var start = storeCurrentPos();
		return parseSubscripts(parseExprAtom(), start, false, curIndent, curLineStart);
	}

	public function parseSubscripts(base:Expression, start:Array<Int>, noCalls:Bool, startIndent:Int, line:Int):Expression {
		while (true) {
			if (curLineStart != line && curIndent <= startIndent && tokenStartsLine()) {
				if (tok.type == tt.dot && curIndent == startIndent) --startIndent;
				else return base;
			}
			if (eat(tt.dot)) {
				var node = startNodeAt(start);
				node.object = base;
				if (curLineStart != line && curIndent <= startIndent && tokenStartsLine()) node.property = dummyIdent();
				else node.property = parsePropertyAccessor() || dummyIdent();
				node.computed = false;
				base = finishNode(node, "MemberExpression");
			} else if (tok.type == tt.bracketL) {
				pushCx();
				next();
				var node = startNodeAt(start);
				node.object = base;
				node.property = parseExpression();
				node.computed = true;
				popCx();
				expect(tt.bracketR);
				base = finishNode(node, "MemberExpression");
			} else if (!noCalls && tok.type == tt.parenL) {
				pushCx();
				var node = startNodeAt(start);
				node.callee = base;
				node.arguments = parseExprList(tt.parenR);
				base = finishNode(node, "CallExpression");
			} else if (tok.type == tt.backQuote) {
				var node = startNodeAt(start);
				node.tag = base;
				node.quasi = parseTemplate();
				base = finishNode(node, "TaggedTemplateExpression");
			} else {
				return base;
			}
		}
	}

	public function parseExprAtom():Expression {
		var node:Expression = null;
		switch (tok.type) {
		case tt._this:
		case tt._super:
			var type = if (tok.type == tt._this) "ThisExpression" else "Super";
			node = startNode();
			next();
			return finishNode(node, type);
		case tt.name:
			var start = storeCurrentPos();
			var id = parseIdent();
			return if (eat(tt.arrow)) parseArrowExpression(startNodeAt(start), [id]) else id;
		case tt.regexp:
			node = startNode();
			var val = tok.value;
			node.regex = { pattern: val.pattern, flags: val.flags };
			node.value = val.value;
			node.raw = input.substr(tok.start, tok.end);
			next();
			return finishNode(node, "Literal");
		case tt.num:
		case tt.string:
			node = startNode();
			node.value = tok.value;
			node.raw = input.substr(tok.start, tok.end);
			next();
			return finishNode(node, "Literal");
		case tt._null:
		case tt._true:
		case tt._false:
			node = startNode();
			node.value = if (tok.type == tt._null) null else if (tok.type == tt._true) true else false;
			node.raw = tok.type.keyword;
			next();
			return finishNode(node, "Literal");
		case tt.parenL:
			var parenStart = storeCurrentPos();
			next();
			var inner = parseExpression();
			expect(tt.parenR);
			if (eat(tt.arrow)) {
				return parseArrowExpression(startNodeAt(parenStart), if (inner.expressions != null) inner.expressions else if (isDummy(inner)) new Array<Expression>() else new Array<Expression>(inner));
			}
			if (options.preserveParens) {
				var par = startNodeAt(parenStart);
				par.expression = inner;
				inner = finishNode(par, "ParenthesizedExpression");
			}
			return inner;
		case tt.bracketL:
			node = startNode();
			pushCx();
			node.elements = parseExprList(tt.bracketR, true);
			return finishNode(node, "ArrayExpression");
		case tt.braceL:
			return parseObj();
		case tt._class:
			return parseClass(false);
		case tt._function:
			node = startNode();
			next();
			return parseFunction(node, false);
		case tt._new:
			return parseNew();
		case tt._yield:
			node = startNode();
			next();
			if (semicolon() || canInsertSemicolon() || (tok.type != tt.star && !tok.type.startsExpr)) {
				node.delegate = false;
				node.argument = null;
			} else {
				node.delegate = eat(tt.star);
				node.argument = parseMaybeAssign();
			}
			return finishNode(node, "YieldExpression");
		case tt.backQuote:
			return parseTemplate();
		default:
			return dummyIdent();
		}
	}

	public function parseNew():NewExpression {
		var node = startNode();
		var startIndent = curIndent;
		var line = curLineStart;
		var meta = parseIdent(true);
		if (options.ecmaVersion >= 6 && eat(tt.dot)) {
			node.meta = meta;
			node.property = parseIdent(true);
			return finishNode(node, "MetaProperty");
		}
		var start = storeCurrentPos();
		node.callee = parseSubscripts(parseExprAtom(), start, true, startIndent, line);
		if (tok.type == tt.parenL) {
			pushCx();
			node.arguments = parseExprList(tt.parenR);
		} else {
			node.arguments = new Array<Expression>();
		}
		return finishNode(node, "NewExpression");
	}

	public function parseTemplateElement():TemplateElement {
		var elem = startNode();
		elem.value = { raw: input.substr(tok.start, tok.end), cooked: tok.value };
		next();
		elem.tail = tok.type == tt.backQuote;
		return finishNode(elem, "TemplateElement");
	}

	public function parseTemplate():TemplateLiteral {
		var node = startNode();
		next();
		node.expressions = new Array<Expression>();
		var curElt = parseTemplateElement();
		node.quasis = new Array<TemplateElement>();
		node.quasis.push(curElt);
		while (!curElt.tail) {
			next();
			node.expressions.push(parseExpression());
			if (expect(tt.braceR)) {
				curElt = parseTemplateElement();
			} else {
				curElt = startNode();
				curElt.value = { cooked: "", raw: "" };
				curElt.tail = true;
			}
			node.quasis.push(curElt);
		}
		expect(tt.backQuote);
		return finishNode(node, "TemplateLiteral");
	}

	public function parseObj():ObjectExpression {
		var node = startNode();
		node.properties = new Array<Property>();
		pushCx();
		var indent = curIndent + 1;
		var line = curLineStart;
		eat(tt.braceL);
		if (curIndent + 1 < indent) {
			indent = curIndent;
			line = curLineStart;
		}
		while (!closes(tt.braceR, indent, line)) {
			var prop = startNode();
			var isGenerator:Bool = false;
			var start:Array<Int> = null;
			if (options.ecmaVersion >= 6) {
				start = storeCurrentPos();
				prop.method = false;
				prop.shorthand = false;
				isGenerator = eat(tt.star);
			}
			parsePropertyName(prop);
			if (isDummy(prop.key)) {
				if (isDummy(parseMaybeAssign())) next();
				eat(tt.comma);
				continue;
			}
			if (eat(tt.colon)) {
				prop.kind = "init";
				prop.value = parseMaybeAssign();
			} else if (options.ecmaVersion >= 6 && (tok.type == tt.parenL || tok.type == tt.braceL)) {
				prop.kind = "init";
				prop.method = true;
				prop.value = parseMethod(isGenerator);
			} else if (options.ecmaVersion >= 5 && prop.key.type == "Identifier" && !prop.computed && (prop.key.name == "get" || prop.key.name == "set") && (tok.type != tt.comma && tok.type != tt.braceR)) {
				prop.kind = prop.key.name;
				parsePropertyName(prop);
				prop.value = parseMethod(false);
			} else {
				prop.kind = "init";
				if (options.ecmaVersion >= 6) {
					if (eat(tt.eq)) {
						var assign = startNodeAt(start);
						assign.operator = "=";
						assign.left = prop.key;
						assign.right = parseMaybeAssign();
						prop.value = finishNode(assign, "AssignmentExpression");
					} else {
						prop.value = prop.key;
					}
				} else {
					prop.value = dummyIdent();
				}
				prop.shorthand = true;
			}
			node.properties.push(finishNode(prop, "Property"));
			eat(tt.comma);
		}
		popCx();
		if (!eat(tt.braceR)) {
			this.last.end = this.tok.start;
			if (options.locations) this.last.loc.end = this.tok.loc.start;
		}
		return finishNode(node, "ObjectExpression");
	}

	public function parsePropertyName(prop:Property) {
		if (options.ecmaVersion >= 6) {
			if (eat(tt.bracketL)) {
				prop.computed = true;
				prop.key = parseExpression();
				expect(tt.bracketR);
				return;
			} else {
				prop.computed = false;
			}
		}
		var key = if (tok.type == tt.num || tok.type == tt.string) parseExprAtom() else parseIdent();
		prop.key = if (key != null) key else dummyIdent();
	}

	public function parsePropertyAccessor():Expression {
		if (tok.type == tt.name || tok.type.keyword) return parseIdent();
		return null;
	}

	public function parseIdent(isMeta:Bool = false):Identifier {
		var name = if (tok.type == tt.name) tok.value else tok.type.keyword;
		if (name == null) return dummyIdent();
		var node = startNode();
		next();
		node.name = name;
		return finishNode(node, "Identifier");
	}

	public function initFunction(node:Function) {
		node.id = null;
		node.params = new Array<Pattern>();
		if (options.ecmaVersion >= 6) {
			node.generator = false;
			node.expression = false;
		}
	}

	public
package;

import haxe.ds.StringMap;
import haxe.io.StringInput;

class LooseParser {
	public var toks:Tokenizer;
	public var options:ParserOptions;
	public var input:String;
	public var tok:Token;
	public var last:Token;
	public var ahead:Array<Token>;
	public var context:Array<Int>;
	public var curIndent:Int;
	public var curLineStart:Int;
	public var nextLineStart:Int;

	public function new(input:String, options:ParserOptions) {
		this.toks = new Tokenizer(new StringInput(input), options);
		this.options = this.toks.options;
		this.input = this.toks.input;
		this.tok = this.last = { type: tt.eof, start: 0, end: 0 };
		if (options.locations) this.tok.loc = new SourceLocation(this.toks, this.toks.curPosition());
		this.ahead = new Array<Token>();
		this.context = new Array<Int>();
		this.curIndent = 0;
		this.curLineStart = 0;
		this.nextLineStart = lineEnd(this.curLineStart) + 1;
	}

	public function parseTopLevel():Program {
		var node = startNodeAt(if (options.locations) {
			[0, getLineInfo(input, 0)]
		} else {
			0
		});
		node.body = new Array<Statement>();
		while (tok.type != tt.eof) node.body.push(parseStatement());
		this.last = tok;
		if (options.ecmaVersion >= 6) node.sourceType = options.sourceType;
		return finishNode(node, "Program");
	}

	public function parseStatement():Statement {
		var starttype = tok.type;
		var node = startNode();
		switch (starttype) {
		case tt._break:
		case tt._continue:
			next();
			var isBreak = starttype == tt._break;
			if (semicolon() || canInsertSemicolon()) {
				node.label = null;
			} else {
				node.label = if (tok.type == tt.name) parseIdent() else null;
				semicolon();
			}
			return finishNode(node, if (isBreak) "BreakStatement" else "ContinueStatement");
		case tt._debugger:
			next();
			semicolon();
			return finishNode(node, "DebuggerStatement");
		case tt._do:
			next();
			node.body = parseStatement();
			node.test = if (eat(tt._while)) parseParenExpression() else dummyIdent();
			semicolon();
			return finishNode(node, "DoWhileStatement");
		case tt._for:
			next();
			pushCx();
			expect(tt.parenL);
			if (tok.type == tt.semi) return parseFor(node, null);
			if (tok.type == tt._var || tok.type == tt._let || tok.type == tt._const) {
				var _init = parseVar(true);
				if (_init.declarations.length == 1 && (tok.type == tt._in || isContextual("of"))) {
					return parseForIn(node, _init);
				}
				return parseFor(node, _init);
			}
			var init = parseExpression(true);
			if (tok.type == tt._in || isContextual("of")) return parseForIn(node, toAssignable(init));
			return parseFor(node, init);
		case tt._function:
			next();
			return parseFunction(node, true);
		case tt._if:
			next();
			node.test = parseParenExpression();
			node.consequent = parseStatement();
			node.alternate = if (eat(tt._else)) parseStatement() else null;
			return finishNode(node, "IfStatement");
		case tt._return:
			next();
			if (eat(tt.semi) || canInsertSemicolon()) node.argument = null;
			else {
				node.argument = parseExpression();
				semicolon();
			}
			return finishNode(node, "ReturnStatement");
		case tt._switch:
			var blockIndent = curIndent;
			var line = curLineStart;
			next();
			node.discriminant = parseParenExpression();
			node.cases = new Array<SwitchCase>();
			pushCx();
			expect(tt.braceL);
			var cur:SwitchCase = null;
			while (!closes(tt.braceR, blockIndent, line, true)) {
				if (tok.type == tt._case || tok.type == tt._default) {
					var isCase = tok.type == tt._case;
					if (cur != null) finishNode(cur, "SwitchCase");
					node.cases.push(cur = startNode());
					cur.consequent = new Array<Statement>();
					next();
					if (isCase) cur.test = parseExpression();
					else cur.test = null;
					expect(tt.colon);
				} else {
					if (cur == null) {
						node.cases.push(cur = startNode());
						cur.consequent = new Array<Statement>();
						cur.test = null;
					}
					cur.consequent.push(parseStatement());
				}
			}
			if (cur != null) finishNode(cur, "SwitchCase");
			popCx();
			eat(tt.braceR);
			return finishNode(node, "SwitchStatement");
		case tt._throw:
			next();
			node.argument = parseExpression();
			semicolon();
			return finishNode(node, "ThrowStatement");
		case tt._try:
			next();
			node.block = parseBlock();
			node.handler = null;
			if (tok.type == tt._catch) {
				var clause = startNode();
				next();
				expect(tt.parenL);
				clause.param = toAssignable(parseExprAtom());
				expect(tt.parenR);
				clause.guard = null;
				clause.body = parseBlock();
				node.handler = finishNode(clause, "CatchClause");
			}
			node.finalizer = if (eat(tt._finally)) parseBlock() else null;
			if (node.handler == null && node.finalizer == null) return node.block;
			return finishNode(node, "TryStatement");
		case tt._var:
		case tt._let:
		case tt._const:
			return parseVar();
		case tt._while:
			next();
			node.test = parseParenExpression();
			node.body = parseStatement();
			return finishNode(node, "WhileStatement");
		case tt._with:
			next();
			node.object = parseParenExpression();
			node.body = parseStatement();
			return finishNode(node, "WithStatement");
		case tt.braceL:
			return parseBlock();
		case tt.semi:
			next();
			return finishNode(node, "EmptyStatement");
		case tt._class:
			return parseClass(true);
		case tt._import:
			return parseImport();
		case tt._export:
			return parseExport();
		default:
			var expr = parseExpression();
			if (isDummy(expr)) {
				next();
				if (tok.type == tt.eof) return finishNode(node, "EmptyStatement");
				return parseStatement();
			} else if (starttype == tt.name && expr.type == "Identifier" && eat(tt.colon)) {
				node.body = parseStatement();
				node.label = expr;
				return finishNode(node, "LabeledStatement");
			} else {
				node.expression = expr;
				semicolon();
				return finishNode(node, "ExpressionStatement");
			}
		}
	}

	public function parseBlock():BlockStatement {
		var node = startNode();
		pushCx();
		expect(tt.braceL);
		var blockIndent = curIndent;
		var line = curLineStart;
		node.body = new Array<Statement>();
		while (!closes(tt.braceR, blockIndent, line, true)) node.body.push(parseStatement());
		popCx();
		eat(tt.braceR);
		return finishNode(node, "BlockStatement");
	}

	public function parseFor(node:ForStatement, init:VariableDeclaration):ForStatement {
		node.init = init;
		node.test = null;
		node.update = null;
		if (eat(tt.semi) && tok.type != tt.semi) node.test = parseExpression();
		if (eat(tt.semi) && tok.type != tt.parenR) node.update = parseExpression();
		popCx();
		expect(tt.parenR);
		node.body = parseStatement();
		return finishNode(node, "ForStatement");
	}

	public function parseForIn(node:ForInStatement, init:VariableDeclaration):ForInStatement {
		var type = if (tok.type == tt._in) "ForInStatement" else "ForOfStatement";
		next();
		node.left = init;
		node.right = parseExpression();
		popCx();
		expect(tt.parenR);
		node.body = parseStatement();
		return finishNode(node, type);
	}

	public function parseVar(noIn:Bool):VariableDeclaration {
		var node = startNode();
		node.kind = tok.type.keyword;
		next();
		node.declarations = new Array<VariableDeclarator>();
		do {
			var decl = startNode();
			decl.id = if (options.ecmaVersion >= 6) toAssignable(parseExprAtom()) else parseIdent();
			decl.init = if (eat(tt.eq)) parseMaybeAssign(noIn) else null;
			node.declarations.push(finishNode(decl, "VariableDeclarator"));
		} while (eat(tt.comma));
		if (node.declarations.length == 0) {
			var decl = startNode();
			decl.id = dummyIdent();
			node.declarations.push(finishNode(decl, "VariableDeclarator"));
		}
		if (!noIn) semicolon();
		return finishNode(node, "VariableDeclaration");
	}

	public function parseClass(isStatement:Bool):ClassDeclaration {
		var node = startNode();
		next();
		if (tok.type == tt.name) node.id = parseIdent();
		else if (isStatement) node.id = dummyIdent();
		else node.id = null;
		node.superClass = if (eat(tt._extends)) parseExpression() else null;
		node.body = startNode();
		node.body.body = new Array<MethodDefinition>();
		pushCx();
		var indent = curIndent + 1;
		var line = curLineStart;
		eat(tt.braceL);
		if (curIndent + 1 < indent) {
			indent = curIndent;
			line = curLineStart;
		}
		while (!closes(tt.braceR, indent, line)) {
			if (semicolon()) continue;
			var method = startNode();
			var isGenerator:Bool = false;
			var start:Array<Int> = null;
			if (options.ecmaVersion >= 6) {
				method["static"] = false;
				isGenerator = eat(tt.star);
			}
			parsePropertyName(method);
			if (isDummy(method.key)) {
				if (isDummy(parseMaybeAssign())) next();
				eat(tt.comma);
				continue;
			}
			if (method.key.type == "Identifier" && !method.computed && method.key.name == "static" && (tok.type != tt.parenL && tok.type != tt.braceL)) {
				method["static"] = true;
				isGenerator = eat(tt.star);
				parsePropertyName(method);
			} else {
				method["static"] = false;
			}
			if (options.ecmaVersion >= 5 && method.key.type == "Identifier" && !method.computed && (method.key.name == "get" || method.key.name == "set") && tok.type != tt.parenL && tok.type != tt.braceL) {
				method.kind = method.key.name;
				parsePropertyName(method);
				method.value = parseMethod(false);
			} else {
				if (!method.computed && !method["static"] && !isGenerator && (method.key.type == "Identifier" && method.key.name == "constructor" || method.key.type == "Literal" && method.key.value == "constructor")) {
					method.kind = "constructor";
				} else {
					method.kind = "method";
				}
				method.value = parseMethod(isGenerator);
			}
			node.body.body.push(finishNode(method, "MethodDefinition"));
		}
		popCx();
		if (!eat(tt.braceR)) {
			this.last.end = this.tok.start;
			if (options.locations) this.last.loc.end = this.tok.loc.start;
		}
		semicolon();
		finishNode(node.body, "ClassBody");
		return finishNode(node, if (isStatement) "ClassDeclaration" else "ClassExpression");
	}

	public function parseFunction(node:FunctionDeclaration, isStatement:Bool):FunctionDeclaration {
		initFunction(node);
		if (options.ecmaVersion >= 6) node.generator = eat(tt.star);
		if (tok.type == tt.name) node.id = parseIdent();
		else if (isStatement) node.id = dummyIdent();
		node.params = parseFunctionParams();
		node.body = parseBlock();
		return finishNode(node, if (isStatement) "FunctionDeclaration" else "FunctionExpression");
	}

	public function parseExport():ExportDeclaration {
		var node = startNode();
		next();
		if (eat(tt.star)) {
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			return finishNode(node, "ExportAllDeclaration");
		}
		if (eat(tt._default)) {
			var expr = parseMaybeAssign();
			if (expr.id != null) {
				switch (expr.type) {
				case "FunctionExpression":
					expr.type = "FunctionDeclaration";
					break;
				case "ClassExpression":
					expr.type = "ClassDeclaration";
					break;
				}
			}
			node.declaration = expr;
			semicolon();
			return finishNode(node, "ExportDefaultDeclaration");
		}
		if (tok.type.keyword) {
			node.declaration = parseStatement();
			node.specifiers = new Array<ExportSpecifier>();
			node.source = null;
		} else {
			node.declaration = null;
			node.specifiers = parseExportSpecifierList();
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			semicolon();
		}
		return finishNode(node, "ExportNamedDeclaration");
	}

	public function parseImport():ImportDeclaration {
		var node = startNode();
		next();
		if (tok.type == tt.string) {
			node.specifiers = new Array<ImportSpecifier>();
			node.source = parseExprAtom();
			node.kind = "";
		} else {
			var elt:ImportSpecifier = null;
			if (tok.type == tt.name && tok.value != "from") {
				elt = startNode();
				elt.local = parseIdent();
				finishNode(elt, "ImportDefaultSpecifier");
				eat(tt.comma);
			}
			node.specifiers = parseImportSpecifierList();
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			if (elt != null) node.specifiers.unshift(elt);
		}
		semicolon();
		return finishNode(node, "ImportDeclaration");
	}

	public function parseImportSpecifierList():Array<ImportSpecifier> {
		var elts = new Array<ImportSpecifier>();
		if (tok.type == tt.star) {
			var elt = startNode();
			next();
			if (eatContextual("as")) elt.local = parseIdent();
			elts.push(finishNode(elt, "ImportNamespaceSpecifier"));
		} else {
			var indent = curIndent;
			var line = curLineStart;
			var continuedLine = nextLineStart;
			pushCx();
			eat(tt.braceL);
			if (curLineStart > continuedLine) continuedLine = curLineStart;
			while (!closes(tt.braceR, indent + (if (curLineStart <= continuedLine) 1 else 0), line)) {
				var elt = startNode();
				if (eat(tt.star)) {
					if (eatContextual("as")) elt.local = parseIdent();
					finishNode(elt, "ImportNamespaceSpecifier");
				} else {
					if (isContextual("from")) break;
					elt.imported = parseIdent();
					elt.local = if (eatContextual("as")) parseIdent() else elt.imported;
					finishNode(elt, "ImportSpecifier");
				}
				elts.push(elt);
				eat(tt.comma);
			}
			eat(tt.braceR);
			popCx();
		}
		return elts;
	}

	public function parseExportSpecifierList():Array<ExportSpecifier> {
		var elts = new Array<ExportSpecifier>();
		var indent = curIndent;
		var line = curLineStart;
		var continuedLine = nextLineStart;
		pushCx();
		eat(tt.braceL);
		if (curLineStart > continuedLine) continuedLine = curLineStart;
		while (!closes(tt.braceR, indent + (if (curLineStart <= continuedLine) 1 else 0), line)) {
			if (isContextual("from")) break;
			var elt = startNode();
			elt.local = parseIdent();
			elt.exported = if (eatContextual("as")) parseIdent() else elt.local;
			finishNode(elt, "ExportSpecifier");
			elts.push(elt);
			eat(tt.comma);
		}
		eat(tt.braceR);
		popCx();
		return elts;
	}

	public function parseExpression(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var expr = parseMaybeAssign(noIn);
		if (tok.type == tt.comma) {
			var node = startNodeAt(start);
			node.expressions = new Array<Expression>();
			node.expressions.push(expr);
			while (eat(tt.comma)) node.expressions.push(parseMaybeAssign(noIn));
			return finishNode(node, "SequenceExpression");
		}
		return expr;
	}

	public function parseParenExpression():Expression {
		pushCx();
		expect(tt.parenL);
		var val = parseExpression();
		popCx();
		expect(tt.parenR);
		return val;
	}

	public function parseMaybeAssign(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var left = parseMaybeConditional(noIn);
		if (tok.type.isAssign) {
			var node = startNodeAt(start);
			node.operator = tok.value;
			node.left = if (tok.type == tt.eq) toAssignable(left) else checkLVal(left);
			next();
			node.right = parseMaybeAssign(noIn);
			return finishNode(node, "AssignmentExpression");
		}
		return left;
	}

	public function parseMaybeConditional(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var expr = parseExprOps(noIn);
		if (eat(tt.question)) {
			var node = startNodeAt(start);
			node.test = expr;
			node.consequent = parseMaybeAssign();
			node.alternate = if (expect(tt.colon)) parseMaybeAssign(noIn) else dummyIdent();
			return finishNode(node, "ConditionalExpression");
		}
		return expr;
	}

	public function parseExprOps(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var indent = curIndent;
		var line = curLineStart;
		return parseExprOp(parseMaybeUnary(noIn), start, -1, noIn, indent, line);
	}

	public function parseExprOp(left:Expression, start:Array<Int>, minPrec:Int, noIn:Bool, indent:Int, line:Int):Expression {
		if (curLineStart != line && curIndent < indent && tokenStartsLine()) return left;
		var prec = tok.type.binop;
		if (prec != null && (!noIn || tok.type != tt._in)) {
			if (prec > minPrec) {
				var node = startNodeAt(start);
				node.left = left;
				node.operator = tok.value;
				next();
				if (curLineStart != line && curIndent < indent && tokenStartsLine()) {
					node.right = dummyIdent();
				} else {
					var rightStart = storeCurrentPos();
					node.right = parseExprOp(parseMaybeUnary(noIn), rightStart, prec, noIn, indent, line);
				}
				this.finishNode(node, if (/"&&"|"||"/.match(node.operator) != null) "LogicalExpression" else "BinaryExpression");
				return parseExprOp(node, start, minPrec, noIn, indent, line);
			}
		}
		return left;
	}

	public function parseMaybeUnary(noIn:Bool = false):Expression {
		if (tok.type.prefix) {
			var node = startNode();
			var update = tok.type == tt.incDec;
			node.operator = tok.value;
			node.prefix = true;
			next();
			node.argument = parseMaybeUnary(noIn);
			if (update) node.argument = checkLVal(node.argument);
			return finishNode(node, if (update) "UpdateExpression" else "UnaryExpression");
		} else if (tok.type == tt.ellipsis) {
			var node = startNode();
			next();
			node.argument = parseMaybeUnary(noIn);
			return finishNode(node, "SpreadElement");
		}
		var start = storeCurrentPos();
		var expr = parseExprSubscripts();
		while (tok.type.postfix && !canInsertSemicolon()) {
			var node = startNodeAt(start);
			node.operator = tok.value;
			node.prefix = false;
			node.argument = checkLVal(expr);
			next();
			expr = finishNode(node, "UpdateExpression");
		}
		return expr;
	}

	public function parseExprSubscripts():Expression {
		var start = storeCurrentPos();
		return parseSubscripts(parseExprAtom(), start, false, curIndent, curLineStart);
	}

	public function parseSubscripts(base:Expression, start:Array<Int>, noCalls:Bool, startIndent:Int, line:Int):Expression {
		while (true) {
			if (curLineStart != line && curIndent <= startIndent && tokenStartsLine()) {
				if (tok.type == tt.dot && curIndent == startIndent) --startIndent;
				else return base;
			}
			if (eat(tt.dot)) {
				var node = startNodeAt(start);
				node.object = base;
				if (curLineStart != line && curIndent <= startIndent && tokenStartsLine()) node.property = dummyIdent();
				else node.property = parsePropertyAccessor() || dummyIdent();
				node.computed = false;
				base = finishNode(node, "MemberExpression");
			} else if (tok.type == tt.bracketL) {
				pushCx();
				next();
				var node = startNodeAt(start);
				node.object = base;
				node.property = parseExpression();
				node.computed = true;
				popCx();
				expect(tt.bracketR);
				base = finishNode(node, "MemberExpression");
			} else if (!noCalls && tok.type == tt.parenL) {
				pushCx();
				var node = startNodeAt(start);
				node.callee = base;
				node.arguments = parseExprList(tt.parenR);
				base = finishNode(node, "CallExpression");
			} else if (tok.type == tt.backQuote) {
				var node = startNodeAt(start);
				node.tag = base;
				node.quasi = parseTemplate();
				base = finishNode(node, "TaggedTemplateExpression");
			} else {
				return base;
			}
		}
	}

	public function parseExprAtom():Expression {
		var node:Expression = null;
		switch (tok.type) {
		case tt._this:
		case tt._super:
			var type = if (tok.type == tt._this) "ThisExpression" else "Super";
			node = startNode();
			next();
			return finishNode(node, type);
		case tt.name:
			var start = storeCurrentPos();
			var id = parseIdent();
			return if (eat(tt.arrow)) parseArrowExpression(startNodeAt(start), [id]) else id;
		case tt.regexp:
			node = startNode();
			var val = tok.value;
			node.regex = { pattern: val.pattern, flags: val.flags };
			node.value = val.value;
			node.raw = input.substr(tok.start, tok.end);
			next();
			return finishNode(node, "Literal");
		case tt.num:
		case tt.string:
			node = startNode();
			node.value = tok.value;
			node.raw = input.substr(tok.start, tok.end);
			next();
			return finishNode(node, "Literal");
		case tt._null:
		case tt._true:
		case tt._false:
			node = startNode();
			node.value = if (tok.type == tt._null) null else if (tok.type == tt._true) true else false;
			node.raw = tok.type.keyword;
			next();
			return finishNode(node, "Literal");
		case tt.parenL:
			var parenStart = storeCurrentPos();
			next();
			var inner = parseExpression();
			expect(tt.parenR);
			if (eat(tt.arrow)) {
				return parseArrowExpression(startNodeAt(parenStart), if (inner.expressions != null) inner.expressions else if (isDummy(inner)) new Array<Expression>() else new Array<Expression>(inner));
			}
			if (options.preserveParens) {
				var par = startNodeAt(parenStart);
				par.expression = inner;
				inner = finishNode(par, "ParenthesizedExpression");
			}
			return inner;
		case tt.bracketL:
			node = startNode();
			pushCx();
			node.elements = parseExprList(tt.bracketR, true);
			return finishNode(node, "ArrayExpression");
		case tt.braceL:
			return parseObj();
		case tt._class:
			return parseClass(false);
		case tt._function:
			node = startNode();
			next();
			return parseFunction(node, false);
		case tt._new:
			return parseNew();
		case tt._yield:
			node = startNode();
			next();
			if (semicolon() || canInsertSemicolon() || (tok.type != tt.star && !tok.type.startsExpr)) {
				node.delegate = false;
				node.argument = null;
			} else {
				node.delegate = eat(tt.star);
				node.argument = parseMaybeAssign();
			}
			return finishNode(node, "YieldExpression");
		case tt.backQuote:
			return parseTemplate();
		default:
			return dummyIdent();
		}
	}

	public function parseNew():NewExpression {
		var node = startNode();
		var startIndent = curIndent;
		var line = curLineStart;
		var meta = parseIdent(true);
		if (options.ecmaVersion >= 6 && eat(tt.dot)) {
			node.meta = meta;
			node.property = parseIdent(true);
			return finishNode(node, "MetaProperty");
		}
		var start = storeCurrentPos();
		node.callee = parseSubscripts(parseExprAtom(), start, true, startIndent, line);
		if (tok.type == tt.parenL) {
			pushCx();
			node.arguments = parseExprList(tt.parenR);
		} else {
			node.arguments = new Array<Expression>();
		}
		return finishNode(node, "NewExpression");
	}

	public function parseTemplateElement():TemplateElement {
		var elem = startNode();
		elem.value = { raw: input.substr(tok.start, tok.end), cooked: tok.value };
		next();
		elem.tail = tok.type == tt.backQuote;
		return finishNode(elem, "TemplateElement");
	}

	public function parseTemplate():TemplateLiteral {
		var node = startNode();
		next();
		node.expressions = new Array<Expression>();
		var curElt = parseTemplateElement();
		node.quasis = new Array<TemplateElement>();
		node.quasis.push(curElt);
		while (!curElt.tail) {
			next();
			node.expressions.push(parseExpression());
			if (expect(tt.braceR)) {
				curElt = parseTemplateElement();
			} else {
				curElt = startNode();
				curElt.value = { cooked: "", raw: "" };
				curElt.tail = true;
			}
			node.quasis.push(curElt);
		}
		expect(tt.backQuote);
		return finishNode(node, "TemplateLiteral");
	}

	public function parseObj():ObjectExpression {
		var node = startNode();
		node.properties = new Array<Property>();
		pushCx();
		var indent = curIndent + 1;
		var line = curLineStart;
		eat(tt.braceL);
		if (curIndent + 1 < indent) {
			indent = curIndent;
			line = curLineStart;
		}
		while (!closes(tt.braceR, indent, line)) {
			var prop = startNode();
			var isGenerator:Bool = false;
			var start:Array<Int> = null;
			if (options.ecmaVersion >= 6) {
				start = storeCurrentPos();
				prop.method = false;
				prop.shorthand = false;
				isGenerator = eat(tt.star);
			}
			parsePropertyName(prop);
			if (isDummy(prop.key)) {
				if (isDummy(parseMaybeAssign())) next();
				eat(tt.comma);
				continue;
			}
			if (eat(tt.colon)) {
				prop.kind = "init";
				prop.value = parseMaybeAssign();
			} else if (options.ecmaVersion >= 6 && (tok.type == tt.parenL || tok.type == tt.braceL)) {
				prop.kind = "init";
				prop.method = true;
				prop.value = parseMethod(isGenerator);
			} else if (options.ecmaVersion >= 5 && prop.key.type == "Identifier" && !prop.computed && (prop.key.name == "get" || prop.key.name == "set") && (tok.type != tt.comma && tok.type != tt.braceR)) {
				prop.kind = prop.key.name;
				parsePropertyName(prop);
				prop.value = parseMethod(false);
			} else {
				prop.kind = "init";
				if (options.ecmaVersion >= 6) {
					if (eat(tt.eq)) {
						var assign = startNodeAt(start);
						assign.operator = "=";
						assign.left = prop.key;
						assign.right = parseMaybeAssign();
						prop.value = finishNode(assign, "AssignmentExpression");
					} else {
						prop.value = prop.key;
					}
				} else {
					prop.value = dummyIdent();
				}
				prop.shorthand = true;
			}
			node.properties.push(finishNode(prop, "Property"));
			eat(tt.comma);
		}
		popCx();
		if (!eat(tt.braceR)) {
			this.last.end = this.tok.start;
			if (options.locations) this.last.loc.end = this.tok.loc.start;
		}
		return finishNode(node, "ObjectExpression");
	}

	public function parsePropertyName(prop:Property) {
		if (options.ecmaVersion >= 6) {
			if (eat(tt.bracketL)) {
				prop.computed = true;
				prop.key = parseExpression();
				expect(tt.bracketR);
				return;
			} else {
				prop.computed = false;
			}
		}
		var key = if (tok.type == tt.num || tok.type == tt.string) parseExprAtom() else parseIdent();
		prop.key = if (key != null) key else dummyIdent();
	}

	public function parsePropertyAccessor():Expression {
		if (tok.type == tt.name || tok.type.keyword) return parseIdent();
		return null;
	}

	public function parseIdent(isMeta:Bool = false):Identifier {
		var name = if (tok.type == tt.name) tok.value else tok.type.keyword;
		if (name == null) return dummyIdent();
		var node = startNode();
		next();
		node.name = name;
		return finishNode(node, "Identifier");
	}

	public function initFunction(node:Function) {
		node.id = null;
		node.params = new Array<Pattern>();
		if (options.ecmaVersion >= 6) {
			node.generator = false;
			node.expression = false;
		}
	}

	public
package;

import haxe.ds.StringMap;
import haxe.io.StringInput;

class LooseParser {
	public var toks:Tokenizer;
	public var options:ParserOptions;
	public var input:String;
	public var tok:Token;
	public var last:Token;
	public var ahead:Array<Token>;
	public var context:Array<Int>;
	public var curIndent:Int;
	public var curLineStart:Int;
	public var nextLineStart:Int;

	public function new(input:String, options:ParserOptions) {
		this.toks = new Tokenizer(new StringInput(input), options);
		this.options = this.toks.options;
		this.input = this.toks.input;
		this.tok = this.last = { type: tt.eof, start: 0, end: 0 };
		if (options.locations) this.tok.loc = new SourceLocation(this.toks, this.toks.curPosition());
		this.ahead = new Array<Token>();
		this.context = new Array<Int>();
		this.curIndent = 0;
		this.curLineStart = 0;
		this.nextLineStart = lineEnd(this.curLineStart) + 1;
	}

	public function parseTopLevel():Program {
		var node = startNodeAt(if (options.locations) {
			[0, getLineInfo(input, 0)]
		} else {
			0
		});
		node.body = new Array<Statement>();
		while (tok.type != tt.eof) node.body.push(parseStatement());
		this.last = tok;
		if (options.ecmaVersion >= 6) node.sourceType = options.sourceType;
		return finishNode(node, "Program");
	}

	public function parseStatement():Statement {
		var starttype = tok.type;
		var node = startNode();
		switch (starttype) {
		case tt._break:
		case tt._continue:
			next();
			var isBreak = starttype == tt._break;
			if (semicolon() || canInsertSemicolon()) {
				node.label = null;
			} else {
				node.label = if (tok.type == tt.name) parseIdent() else null;
				semicolon();
			}
			return finishNode(node, if (isBreak) "BreakStatement" else "ContinueStatement");
		case tt._debugger:
			next();
			semicolon();
			return finishNode(node, "DebuggerStatement");
		case tt._do:
			next();
			node.body = parseStatement();
			node.test = if (eat(tt._while)) parseParenExpression() else dummyIdent();
			semicolon();
			return finishNode(node, "DoWhileStatement");
		case tt._for:
			next();
			pushCx();
			expect(tt.parenL);
			if (tok.type == tt.semi) return parseFor(node, null);
			if (tok.type == tt._var || tok.type == tt._let || tok.type == tt._const) {
				var _init = parseVar(true);
				if (_init.declarations.length == 1 && (tok.type == tt._in || isContextual("of"))) {
					return parseForIn(node, _init);
				}
				return parseFor(node, _init);
			}
			var init = parseExpression(true);
			if (tok.type == tt._in || isContextual("of")) return parseForIn(node, toAssignable(init));
			return parseFor(node, init);
		case tt._function:
			next();
			return parseFunction(node, true);
		case tt._if:
			next();
			node.test = parseParenExpression();
			node.consequent = parseStatement();
			node.alternate = if (eat(tt._else)) parseStatement() else null;
			return finishNode(node, "IfStatement");
		case tt._return:
			next();
			if (eat(tt.semi) || canInsertSemicolon()) node.argument = null;
			else {
				node.argument = parseExpression();
				semicolon();
			}
			return finishNode(node, "ReturnStatement");
		case tt._switch:
			var blockIndent = curIndent;
			var line = curLineStart;
			next();
			node.discriminant = parseParenExpression();
			node.cases = new Array<SwitchCase>();
			pushCx();
			expect(tt.braceL);
			var cur:SwitchCase = null;
			while (!closes(tt.braceR, blockIndent, line, true)) {
				if (tok.type == tt._case || tok.type == tt._default) {
					var isCase = tok.type == tt._case;
					if (cur != null) finishNode(cur, "SwitchCase");
					node.cases.push(cur = startNode());
					cur.consequent = new Array<Statement>();
					next();
					if (isCase) cur.test = parseExpression();
					else cur.test = null;
					expect(tt.colon);
				} else {
					if (cur == null) {
						node.cases.push(cur = startNode());
						cur.consequent = new Array<Statement>();
						cur.test = null;
					}
					cur.consequent.push(parseStatement());
				}
			}
			if (cur != null) finishNode(cur, "SwitchCase");
			popCx();
			eat(tt.braceR);
			return finishNode(node, "SwitchStatement");
		case tt._throw:
			next();
			node.argument = parseExpression();
			semicolon();
			return finishNode(node, "ThrowStatement");
		case tt._try:
			next();
			node.block = parseBlock();
			node.handler = null;
			if (tok.type == tt._catch) {
				var clause = startNode();
				next();
				expect(tt.parenL);
				clause.param = toAssignable(parseExprAtom());
				expect(tt.parenR);
				clause.guard = null;
				clause.body = parseBlock();
				node.handler = finishNode(clause, "CatchClause");
			}
			node.finalizer = if (eat(tt._finally)) parseBlock() else null;
			if (node.handler == null && node.finalizer == null) return node.block;
			return finishNode(node, "TryStatement");
		case tt._var:
		case tt._let:
		case tt._const:
			return parseVar();
		case tt._while:
			next();
			node.test = parseParenExpression();
			node.body = parseStatement();
			return finishNode(node, "WhileStatement");
		case tt._with:
			next();
			node.object = parseParenExpression();
			node.body = parseStatement();
			return finishNode(node, "WithStatement");
		case tt.braceL:
			return parseBlock();
		case tt.semi:
			next();
			return finishNode(node, "EmptyStatement");
		case tt._class:
			return parseClass(true);
		case tt._import:
			return parseImport();
		case tt._export:
			return parseExport();
		default:
			var expr = parseExpression();
			if (isDummy(expr)) {
				next();
				if (tok.type == tt.eof) return finishNode(node, "EmptyStatement");
				return parseStatement();
			} else if (starttype == tt.name && expr.type == "Identifier" && eat(tt.colon)) {
				node.body = parseStatement();
				node.label = expr;
				return finishNode(node, "LabeledStatement");
			} else {
				node.expression = expr;
				semicolon();
				return finishNode(node, "ExpressionStatement");
			}
		}
	}

	public function parseBlock():BlockStatement {
		var node = startNode();
		pushCx();
		expect(tt.braceL);
		var blockIndent = curIndent;
		var line = curLineStart;
		node.body = new Array<Statement>();
		while (!closes(tt.braceR, blockIndent, line, true)) node.body.push(parseStatement());
		popCx();
		eat(tt.braceR);
		return finishNode(node, "BlockStatement");
	}

	public function parseFor(node:ForStatement, init:VariableDeclaration):ForStatement {
		node.init = init;
		node.test = null;
		node.update = null;
		if (eat(tt.semi) && tok.type != tt.semi) node.test = parseExpression();
		if (eat(tt.semi) && tok.type != tt.parenR) node.update = parseExpression();
		popCx();
		expect(tt.parenR);
		node.body = parseStatement();
		return finishNode(node, "ForStatement");
	}

	public function parseForIn(node:ForInStatement, init:VariableDeclaration):ForInStatement {
		var type = if (tok.type == tt._in) "ForInStatement" else "ForOfStatement";
		next();
		node.left = init;
		node.right = parseExpression();
		popCx();
		expect(tt.parenR);
		node.body = parseStatement();
		return finishNode(node, type);
	}

	public function parseVar(noIn:Bool):VariableDeclaration {
		var node = startNode();
		node.kind = tok.type.keyword;
		next();
		node.declarations = new Array<VariableDeclarator>();
		do {
			var decl = startNode();
			decl.id = if (options.ecmaVersion >= 6) toAssignable(parseExprAtom()) else parseIdent();
			decl.init = if (eat(tt.eq)) parseMaybeAssign(noIn) else null;
			node.declarations.push(finishNode(decl, "VariableDeclarator"));
		} while (eat(tt.comma));
		if (node.declarations.length == 0) {
			var decl = startNode();
			decl.id = dummyIdent();
			node.declarations.push(finishNode(decl, "VariableDeclarator"));
		}
		if (!noIn) semicolon();
		return finishNode(node, "VariableDeclaration");
	}

	public function parseClass(isStatement:Bool):ClassDeclaration {
		var node = startNode();
		next();
		if (tok.type == tt.name) node.id = parseIdent();
		else if (isStatement) node.id = dummyIdent();
		else node.id = null;
		node.superClass = if (eat(tt._extends)) parseExpression() else null;
		node.body = startNode();
		node.body.body = new Array<MethodDefinition>();
		pushCx();
		var indent = curIndent + 1;
		var line = curLineStart;
		eat(tt.braceL);
		if (curIndent + 1 < indent) {
			indent = curIndent;
			line = curLineStart;
		}
		while (!closes(tt.braceR, indent, line)) {
			if (semicolon()) continue;
			var method = startNode();
			var isGenerator:Bool = false;
			var start:Array<Int> = null;
			if (options.ecmaVersion >= 6) {
				method["static"] = false;
				isGenerator = eat(tt.star);
			}
			parsePropertyName(method);
			if (isDummy(method.key)) {
				if (isDummy(parseMaybeAssign())) next();
				eat(tt.comma);
				continue;
			}
			if (method.key.type == "Identifier" && !method.computed && method.key.name == "static" && (tok.type != tt.parenL && tok.type != tt.braceL)) {
				method["static"] = true;
				isGenerator = eat(tt.star);
				parsePropertyName(method);
			} else {
				method["static"] = false;
			}
			if (options.ecmaVersion >= 5 && method.key.type == "Identifier" && !method.computed && (method.key.name == "get" || method.key.name == "set") && tok.type != tt.parenL && tok.type != tt.braceL) {
				method.kind = method.key.name;
				parsePropertyName(method);
				method.value = parseMethod(false);
			} else {
				if (!method.computed && !method["static"] && !isGenerator && (method.key.type == "Identifier" && method.key.name == "constructor" || method.key.type == "Literal" && method.key.value == "constructor")) {
					method.kind = "constructor";
				} else {
					method.kind = "method";
				}
				method.value = parseMethod(isGenerator);
			}
			node.body.body.push(finishNode(method, "MethodDefinition"));
		}
		popCx();
		if (!eat(tt.braceR)) {
			this.last.end = this.tok.start;
			if (options.locations) this.last.loc.end = this.tok.loc.start;
		}
		semicolon();
		finishNode(node.body, "ClassBody");
		return finishNode(node, if (isStatement) "ClassDeclaration" else "ClassExpression");
	}

	public function parseFunction(node:FunctionDeclaration, isStatement:Bool):FunctionDeclaration {
		initFunction(node);
		if (options.ecmaVersion >= 6) node.generator = eat(tt.star);
		if (tok.type == tt.name) node.id = parseIdent();
		else if (isStatement) node.id = dummyIdent();
		node.params = parseFunctionParams();
		node.body = parseBlock();
		return finishNode(node, if (isStatement) "FunctionDeclaration" else "FunctionExpression");
	}

	public function parseExport():ExportDeclaration {
		var node = startNode();
		next();
		if (eat(tt.star)) {
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			return finishNode(node, "ExportAllDeclaration");
		}
		if (eat(tt._default)) {
			var expr = parseMaybeAssign();
			if (expr.id != null) {
				switch (expr.type) {
				case "FunctionExpression":
					expr.type = "FunctionDeclaration";
					break;
				case "ClassExpression":
					expr.type = "ClassDeclaration";
					break;
				}
			}
			node.declaration = expr;
			semicolon();
			return finishNode(node, "ExportDefaultDeclaration");
		}
		if (tok.type.keyword) {
			node.declaration = parseStatement();
			node.specifiers = new Array<ExportSpecifier>();
			node.source = null;
		} else {
			node.declaration = null;
			node.specifiers = parseExportSpecifierList();
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			semicolon();
		}
		return finishNode(node, "ExportNamedDeclaration");
	}

	public function parseImport():ImportDeclaration {
		var node = startNode();
		next();
		if (tok.type == tt.string) {
			node.specifiers = new Array<ImportSpecifier>();
			node.source = parseExprAtom();
			node.kind = "";
		} else {
			var elt:ImportSpecifier = null;
			if (tok.type == tt.name && tok.value != "from") {
				elt = startNode();
				elt.local = parseIdent();
				finishNode(elt, "ImportDefaultSpecifier");
				eat(tt.comma);
			}
			node.specifiers = parseImportSpecifierList();
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			if (elt != null) node.specifiers.unshift(elt);
		}
		semicolon();
		return finishNode(node, "ImportDeclaration");
	}

	public function parseImportSpecifierList():Array<ImportSpecifier> {
		var elts = new Array<ImportSpecifier>();
		if (tok.type == tt.star) {
			var elt = startNode();
			next();
			if (eatContextual("as")) elt.local = parseIdent();
			elts.push(finishNode(elt, "ImportNamespaceSpecifier"));
		} else {
			var indent = curIndent;
			var line = curLineStart;
			var continuedLine = nextLineStart;
			pushCx();
			eat(tt.braceL);
			if (curLineStart > continuedLine) continuedLine = curLineStart;
			while (!closes(tt.braceR, indent + (if (curLineStart <= continuedLine) 1 else 0), line)) {
				var elt = startNode();
				if (eat(tt.star)) {
					if (eatContextual("as")) elt.local = parseIdent();
					finishNode(elt, "ImportNamespaceSpecifier");
				} else {
					if (isContextual("from")) break;
					elt.imported = parseIdent();
					elt.local = if (eatContextual("as")) parseIdent() else elt.imported;
					finishNode(elt, "ImportSpecifier");
				}
				elts.push(elt);
				eat(tt.comma);
			}
			eat(tt.braceR);
			popCx();
		}
		return elts;
	}

	public function parseExportSpecifierList():Array<ExportSpecifier> {
		var elts = new Array<ExportSpecifier>();
		var indent = curIndent;
		var line = curLineStart;
		var continuedLine = nextLineStart;
		pushCx();
		eat(tt.braceL);
		if (curLineStart > continuedLine) continuedLine = curLineStart;
		while (!closes(tt.braceR, indent + (if (curLineStart <= continuedLine) 1 else 0), line)) {
			if (isContextual("from")) break;
			var elt = startNode();
			elt.local = parseIdent();
			elt.exported = if (eatContextual("as")) parseIdent() else elt.local;
			finishNode(elt, "ExportSpecifier");
			elts.push(elt);
			eat(tt.comma);
		}
		eat(tt.braceR);
		popCx();
		return elts;
	}

	public function parseExpression(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var expr = parseMaybeAssign(noIn);
		if (tok.type == tt.comma) {
			var node = startNodeAt(start);
			node.expressions = new Array<Expression>();
			node.expressions.push(expr);
			while (eat(tt.comma)) node.expressions.push(parseMaybeAssign(noIn));
			return finishNode(node, "SequenceExpression");
		}
		return expr;
	}

	public function parseParenExpression():Expression {
		pushCx();
		expect(tt.parenL);
		var val = parseExpression();
		popCx();
		expect(tt.parenR);
		return val;
	}

	public function parseMaybeAssign(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var left = parseMaybeConditional(noIn);
		if (tok.type.isAssign) {
			var node = startNodeAt(start);
			node.operator = tok.value;
			node.left = if (tok.type == tt.eq) toAssignable(left) else checkLVal(left);
			next();
			node.right = parseMaybeAssign(noIn);
			return finishNode(node, "AssignmentExpression");
		}
		return left;
	}

	public function parseMaybeConditional(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var expr = parseExprOps(noIn);
		if (eat(tt.question)) {
			var node = startNodeAt(start);
			node.test = expr;
			node.consequent = parseMaybeAssign();
			node.alternate = if (expect(tt.colon)) parseMaybeAssign(noIn) else dummyIdent();
			return finishNode(node, "ConditionalExpression");
		}
		return expr;
	}

	public function parseExprOps(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var indent = curIndent;
		var line = curLineStart;
		return parseExprOp(parseMaybeUnary(noIn), start, -1, noIn, indent, line);
	}

	public function parseExprOp(left:Expression, start:Array<Int>, minPrec:Int, noIn:Bool, indent:Int, line:Int):Expression {
		if (curLineStart != line && curIndent < indent && tokenStartsLine()) return left;
		var prec = tok.type.binop;
		if (prec != null && (!noIn || tok.type != tt._in)) {
			if (prec > minPrec) {
				var node = startNodeAt(start);
				node.left = left;
				node.operator = tok.value;
				next();
				if (curLineStart != line && curIndent < indent && tokenStartsLine()) {
					node.right = dummyIdent();
				} else {
					var rightStart = storeCurrentPos();
					node.right = parseExprOp(parseMaybeUnary(noIn), rightStart, prec, noIn, indent, line);
				}
				this.finishNode(node, if (/"&&"|"||"/.match(node.operator) != null) "LogicalExpression" else "BinaryExpression");
				return parseExprOp(node, start, minPrec, noIn, indent, line);
			}
		}
		return left;
	}

	public function parseMaybeUnary(noIn:Bool = false):Expression {
		if (tok.type.prefix) {
			var node = startNode();
			var update = tok.type == tt.incDec;
			node.operator = tok.value;
			node.prefix = true;
			next();
			node.argument = parseMaybeUnary(noIn);
			if (update) node.argument = checkLVal(node.argument);
			return finishNode(node, if (update) "UpdateExpression" else "UnaryExpression");
		} else if (tok.type == tt.ellipsis) {
			var node = startNode();
			next();
			node.argument = parseMaybeUnary(noIn);
			return finishNode(node, "SpreadElement");
		}
		var start = storeCurrentPos();
		var expr = parseExprSubscripts();
		while (tok.type.postfix && !canInsertSemicolon()) {
			var node = startNodeAt(start);
			node.operator = tok.value;
			node.prefix = false;
			node.argument = checkLVal(expr);
			next();
			expr = finishNode(node, "UpdateExpression");
		}
		return expr;
	}

	public function parseExprSubscripts():Expression {
		var start = storeCurrentPos();
		return parseSubscripts(parseExprAtom(), start, false, curIndent, curLineStart);
	}

	public function parseSubscripts(base:Expression, start:Array<Int>, noCalls:Bool, startIndent:Int, line:Int):Expression {
		while (true) {
			if (curLineStart != line && curIndent <= startIndent && tokenStartsLine()) {
				if (tok.type == tt.dot && curIndent == startIndent) --startIndent;
				else return base;
			}
			if (eat(tt.dot)) {
				var node = startNodeAt(start);
				node.object = base;
				if (curLineStart != line && curIndent <= startIndent && tokenStartsLine()) node.property = dummyIdent();
				else node.property = parsePropertyAccessor() || dummyIdent();
				node.computed = false;
				base = finishNode(node, "MemberExpression");
			} else if (tok.type == tt.bracketL) {
				pushCx();
				next();
				var node = startNodeAt(start);
				node.object = base;
				node.property = parseExpression();
				node.computed = true;
				popCx();
				expect(tt.bracketR);
				base = finishNode(node, "MemberExpression");
			} else if (!noCalls && tok.type == tt.parenL) {
				pushCx();
				var node = startNodeAt(start);
				node.callee = base;
				node.arguments = parseExprList(tt.parenR);
				base = finishNode(node, "CallExpression");
			} else if (tok.type == tt.backQuote) {
				var node = startNodeAt(start);
				node.tag = base;
				node.quasi = parseTemplate();
				base = finishNode(node, "TaggedTemplateExpression");
			} else {
				return base;
			}
		}
	}

	public function parseExprAtom():Expression {
		var node:Expression = null;
		switch (tok.type) {
		case tt._this:
		case tt._super:
			var type = if (tok.type == tt._this) "ThisExpression" else "Super";
			node = startNode();
			next();
			return finishNode(node, type);
		case tt.name:
			var start = storeCurrentPos();
			var id = parseIdent();
			return if (eat(tt.arrow)) parseArrowExpression(startNodeAt(start), [id]) else id;
		case tt.regexp:
			node = startNode();
			var val = tok.value;
			node.regex = { pattern: val.pattern, flags: val.flags };
			node.value = val.value;
			node.raw = input.substr(tok.start, tok.end);
			next();
			return finishNode(node, "Literal");
		case tt.num:
		case tt.string:
			node = startNode();
			node.value = tok.value;
			node.raw = input.substr(tok.start, tok.end);
			next();
			return finishNode(node, "Literal");
		case tt._null:
		case tt._true:
		case tt._false:
			node = startNode();
			node.value = if (tok.type == tt._null) null else if (tok.type == tt._true) true else false;
			node.raw = tok.type.keyword;
			next();
			return finishNode(node, "Literal");
		case tt.parenL:
			var parenStart = storeCurrentPos();
			next();
			var inner = parseExpression();
			expect(tt.parenR);
			if (eat(tt.arrow)) {
				return parseArrowExpression(startNodeAt(parenStart), if (inner.expressions != null) inner.expressions else if (isDummy(inner)) new Array<Expression>() else new Array<Expression>(inner));
			}
			if (options.preserveParens) {
				var par = startNodeAt(parenStart);
				par.expression = inner;
				inner = finishNode(par, "ParenthesizedExpression");
			}
			return inner;
		case tt.bracketL:
			node = startNode();
			pushCx();
			node.elements = parseExprList(tt.bracketR, true);
			return finishNode(node, "ArrayExpression");
		case tt.braceL:
			return parseObj();
		case tt._class:
			return parseClass(false);
		case tt._function:
			node = startNode();
			next();
			return parseFunction(node, false);
		case tt._new:
			return parseNew();
		case tt._yield:
			node = startNode();
			next();
			if (semicolon() || canInsertSemicolon() || (tok.type != tt.star && !tok.type.startsExpr)) {
				node.delegate = false;
				node.argument = null;
			} else {
				node.delegate = eat(tt.star);
				node.argument = parseMaybeAssign();
			}
			return finishNode(node, "YieldExpression");
		case tt.backQuote:
			return parseTemplate();
		default:
			return dummyIdent();
		}
	}

	public function parseNew():NewExpression {
		var node = startNode();
		var startIndent = curIndent;
		var line = curLineStart;
		var meta = parseIdent(true);
		if (options.ecmaVersion >= 6 && eat(tt.dot)) {
			node.meta = meta;
			node.property = parseIdent(true);
			return finishNode(node, "MetaProperty");
		}
		var start = storeCurrentPos();
		node.callee = parseSubscripts(parseExprAtom(), start, true, startIndent, line);
		if (tok.type == tt.parenL) {
			pushCx();
			node.arguments = parseExprList(tt.parenR);
		} else {
			node.arguments = new Array<Expression>();
		}
		return finishNode(node, "NewExpression");
	}

	public function parseTemplateElement():TemplateElement {
		var elem = startNode();
		elem.value = { raw: input.substr(tok.start, tok.end), cooked: tok.value };
		next();
		elem.tail = tok.type == tt.backQuote;
		return finishNode(elem, "TemplateElement");
	}

	public function parseTemplate():TemplateLiteral {
		var node = startNode();
		next();
		node.expressions = new Array<Expression>();
		var curElt = parseTemplateElement();
		node.quasis = new Array<TemplateElement>();
		node.quasis.push(curElt);
		while (!curElt.tail) {
			next();
			node.expressions.push(parseExpression());
			if (expect(tt.braceR)) {
				curElt = parseTemplateElement();
			} else {
				curElt = startNode();
				curElt.value = { cooked: "", raw: "" };
				curElt.tail = true;
			}
			node.quasis.push(curElt);
		}
		expect(tt.backQuote);
		return finishNode(node, "TemplateLiteral");
	}

	public function parseObj():ObjectExpression {
		var node = startNode();
		node.properties = new Array<Property>();
		pushCx();
		var indent = curIndent + 1;
		var line = curLineStart;
		eat(tt.braceL);
		if (curIndent + 1 < indent) {
			indent = curIndent;
			line = curLineStart;
		}
		while (!closes(tt.braceR, indent, line)) {
			var prop = startNode();
			var isGenerator:Bool = false;
			var start:Array<Int> = null;
			if (options.ecmaVersion >= 6) {
				start = storeCurrentPos();
				prop.method = false;
				prop.shorthand = false;
				isGenerator = eat(tt.star);
			}
			parsePropertyName(prop);
			if (isDummy(prop.key)) {
				if (isDummy(parseMaybeAssign())) next();
				eat(tt.comma);
				continue;
			}
			if (eat(tt.colon)) {
				prop.kind = "init";
				prop.value = parseMaybeAssign();
			} else if (options.ecmaVersion >= 6 && (tok.type == tt.parenL || tok.type == tt.braceL)) {
				prop.kind = "init";
				prop.method = true;
				prop.value = parseMethod(isGenerator);
			} else if (options.ecmaVersion >= 5 && prop.key.type == "Identifier" && !prop.computed && (prop.key.name == "get" || prop.key.name == "set") && (tok.type != tt.comma && tok.type != tt.braceR)) {
				prop.kind = prop.key.name;
				parsePropertyName(prop);
				prop.value = parseMethod(false);
			} else {
				prop.kind = "init";
				if (options.ecmaVersion >= 6) {
					if (eat(tt.eq)) {
						var assign = startNodeAt(start);
						assign.operator = "=";
						assign.left = prop.key;
						assign.right = parseMaybeAssign();
						prop.value = finishNode(assign, "AssignmentExpression");
					} else {
						prop.value = prop.key;
					}
				} else {
					prop.value = dummyIdent();
				}
				prop.shorthand = true;
			}
			node.properties.push(finishNode(prop, "Property"));
			eat(tt.comma);
		}
		popCx();
		if (!eat(tt.braceR)) {
			this.last.end = this.tok.start;
			if (options.locations) this.last.loc.end = this.tok.loc.start;
		}
		return finishNode(node, "ObjectExpression");
	}

	public function parsePropertyName(prop:Property) {
		if (options.ecmaVersion >= 6) {
			if (eat(tt.bracketL)) {
				prop.computed = true;
				prop.key = parseExpression();
				expect(tt.bracketR);
				return;
			} else {
				prop.computed = false;
			}
		}
		var key = if (tok.type == tt.num || tok.type == tt.string) parseExprAtom() else parseIdent();
		prop.key = if (key != null) key else dummyIdent();
	}

	public function parsePropertyAccessor():Expression {
		if (tok.type == tt.name || tok.type.keyword) return parseIdent();
		return null;
	}

	public function parseIdent(isMeta:Bool = false):Identifier {
		var name = if (tok.type == tt.name) tok.value else tok.type.keyword;
		if (name == null) return dummyIdent();
		var node = startNode();
		next();
		node.name = name;
		return finishNode(node, "Identifier");
	}

	public function initFunction(node:Function) {
		node.id = null;
		node.params = new Array<Pattern>();
		if (options.ecmaVersion >= 6) {
			node.generator = false;
			node.expression = false;
		}
	}

	public
package;

import haxe.ds.StringMap;
import haxe.io.StringInput;

class LooseParser {
	public var toks:Tokenizer;
	public var options:ParserOptions;
	public var input:String;
	public var tok:Token;
	public var last:Token;
	public var ahead:Array<Token>;
	public var context:Array<Int>;
	public var curIndent:Int;
	public var curLineStart:Int;
	public var nextLineStart:Int;

	public function new(input:String, options:ParserOptions) {
		this.toks = new Tokenizer(new StringInput(input), options);
		this.options = this.toks.options;
		this.input = this.toks.input;
		this.tok = this.last = { type: tt.eof, start: 0, end: 0 };
		if (options.locations) this.tok.loc = new SourceLocation(this.toks, this.toks.curPosition());
		this.ahead = new Array<Token>();
		this.context = new Array<Int>();
		this.curIndent = 0;
		this.curLineStart = 0;
		this.nextLineStart = lineEnd(this.curLineStart) + 1;
	}

	public function parseTopLevel():Program {
		var node = startNodeAt(if (options.locations) {
			[0, getLineInfo(input, 0)]
		} else {
			0
		});
		node.body = new Array<Statement>();
		while (tok.type != tt.eof) node.body.push(parseStatement());
		this.last = tok;
		if (options.ecmaVersion >= 6) node.sourceType = options.sourceType;
		return finishNode(node, "Program");
	}

	public function parseStatement():Statement {
		var starttype = tok.type;
		var node = startNode();
		switch (starttype) {
		case tt._break:
		case tt._continue:
			next();
			var isBreak = starttype == tt._break;
			if (semicolon() || canInsertSemicolon()) {
				node.label = null;
			} else {
				node.label = if (tok.type == tt.name) parseIdent() else null;
				semicolon();
			}
			return finishNode(node, if (isBreak) "BreakStatement" else "ContinueStatement");
		case tt._debugger:
			next();
			semicolon();
			return finishNode(node, "DebuggerStatement");
		case tt._do:
			next();
			node.body = parseStatement();
			node.test = if (eat(tt._while)) parseParenExpression() else dummyIdent();
			semicolon();
			return finishNode(node, "DoWhileStatement");
		case tt._for:
			next();
			pushCx();
			expect(tt.parenL);
			if (tok.type == tt.semi) return parseFor(node, null);
			if (tok.type == tt._var || tok.type == tt._let || tok.type == tt._const) {
				var _init = parseVar(true);
				if (_init.declarations.length == 1 && (tok.type == tt._in || isContextual("of"))) {
					return parseForIn(node, _init);
				}
				return parseFor(node, _init);
			}
			var init = parseExpression(true);
			if (tok.type == tt._in || isContextual("of")) return parseForIn(node, toAssignable(init));
			return parseFor(node, init);
		case tt._function:
			next();
			return parseFunction(node, true);
		case tt._if:
			next();
			node.test = parseParenExpression();
			node.consequent = parseStatement();
			node.alternate = if (eat(tt._else)) parseStatement() else null;
			return finishNode(node, "IfStatement");
		case tt._return:
			next();
			if (eat(tt.semi) || canInsertSemicolon()) node.argument = null;
			else {
				node.argument = parseExpression();
				semicolon();
			}
			return finishNode(node, "ReturnStatement");
		case tt._switch:
			var blockIndent = curIndent;
			var line = curLineStart;
			next();
			node.discriminant = parseParenExpression();
			node.cases = new Array<SwitchCase>();
			pushCx();
			expect(tt.braceL);
			var cur:SwitchCase = null;
			while (!closes(tt.braceR, blockIndent, line, true)) {
				if (tok.type == tt._case || tok.type == tt._default) {
					var isCase = tok.type == tt._case;
					if (cur != null) finishNode(cur, "SwitchCase");
					node.cases.push(cur = startNode());
					cur.consequent = new Array<Statement>();
					next();
					if (isCase) cur.test = parseExpression();
					else cur.test = null;
					expect(tt.colon);
				} else {
					if (cur == null) {
						node.cases.push(cur = startNode());
						cur.consequent = new Array<Statement>();
						cur.test = null;
					}
					cur.consequent.push(parseStatement());
				}
			}
			if (cur != null) finishNode(cur, "SwitchCase");
			popCx();
			eat(tt.braceR);
			return finishNode(node, "SwitchStatement");
		case tt._throw:
			next();
			node.argument = parseExpression();
			semicolon();
			return finishNode(node, "ThrowStatement");
		case tt._try:
			next();
			node.block = parseBlock();
			node.handler = null;
			if (tok.type == tt._catch) {
				var clause = startNode();
				next();
				expect(tt.parenL);
				clause.param = toAssignable(parseExprAtom());
				expect(tt.parenR);
				clause.guard = null;
				clause.body = parseBlock();
				node.handler = finishNode(clause, "CatchClause");
			}
			node.finalizer = if (eat(tt._finally)) parseBlock() else null;
			if (node.handler == null && node.finalizer == null) return node.block;
			return finishNode(node, "TryStatement");
		case tt._var:
		case tt._let:
		case tt._const:
			return parseVar();
		case tt._while:
			next();
			node.test = parseParenExpression();
			node.body = parseStatement();
			return finishNode(node, "WhileStatement");
		case tt._with:
			next();
			node.object = parseParenExpression();
			node.body = parseStatement();
			return finishNode(node, "WithStatement");
		case tt.braceL:
			return parseBlock();
		case tt.semi:
			next();
			return finishNode(node, "EmptyStatement");
		case tt._class:
			return parseClass(true);
		case tt._import:
			return parseImport();
		case tt._export:
			return parseExport();
		default:
			var expr = parseExpression();
			if (isDummy(expr)) {
				next();
				if (tok.type == tt.eof) return finishNode(node, "EmptyStatement");
				return parseStatement();
			} else if (starttype == tt.name && expr.type == "Identifier" && eat(tt.colon)) {
				node.body = parseStatement();
				node.label = expr;
				return finishNode(node, "LabeledStatement");
			} else {
				node.expression = expr;
				semicolon();
				return finishNode(node, "ExpressionStatement");
			}
		}
	}

	public function parseBlock():BlockStatement {
		var node = startNode();
		pushCx();
		expect(tt.braceL);
		var blockIndent = curIndent;
		var line = curLineStart;
		node.body = new Array<Statement>();
		while (!closes(tt.braceR, blockIndent, line, true)) node.body.push(parseStatement());
		popCx();
		eat(tt.braceR);
		return finishNode(node, "BlockStatement");
	}

	public function parseFor(node:ForStatement, init:VariableDeclaration):ForStatement {
		node.init = init;
		node.test = null;
		node.update = null;
		if (eat(tt.semi) && tok.type != tt.semi) node.test = parseExpression();
		if (eat(tt.semi) && tok.type != tt.parenR) node.update = parseExpression();
		popCx();
		expect(tt.parenR);
		node.body = parseStatement();
		return finishNode(node, "ForStatement");
	}

	public function parseForIn(node:ForInStatement, init:VariableDeclaration):ForInStatement {
		var type = if (tok.type == tt._in) "ForInStatement" else "ForOfStatement";
		next();
		node.left = init;
		node.right = parseExpression();
		popCx();
		expect(tt.parenR);
		node.body = parseStatement();
		return finishNode(node, type);
	}

	public function parseVar(noIn:Bool):VariableDeclaration {
		var node = startNode();
		node.kind = tok.type.keyword;
		next();
		node.declarations = new Array<VariableDeclarator>();
		do {
			var decl = startNode();
			decl.id = if (options.ecmaVersion >= 6) toAssignable(parseExprAtom()) else parseIdent();
			decl.init = if (eat(tt.eq)) parseMaybeAssign(noIn) else null;
			node.declarations.push(finishNode(decl, "VariableDeclarator"));
		} while (eat(tt.comma));
		if (node.declarations.length == 0) {
			var decl = startNode();
			decl.id = dummyIdent();
			node.declarations.push(finishNode(decl, "VariableDeclarator"));
		}
		if (!noIn) semicolon();
		return finishNode(node, "VariableDeclaration");
	}

	public function parseClass(isStatement:Bool):ClassDeclaration {
		var node = startNode();
		next();
		if (tok.type == tt.name) node.id = parseIdent();
		else if (isStatement) node.id = dummyIdent();
		else node.id = null;
		node.superClass = if (eat(tt._extends)) parseExpression() else null;
		node.body = startNode();
		node.body.body = new Array<MethodDefinition>();
		pushCx();
		var indent = curIndent + 1;
		var line = curLineStart;
		eat(tt.braceL);
		if (curIndent + 1 < indent) {
			indent = curIndent;
			line = curLineStart;
		}
		while (!closes(tt.braceR, indent, line)) {
			if (semicolon()) continue;
			var method = startNode();
			var isGenerator:Bool = false;
			var start:Array<Int> = null;
			if (options.ecmaVersion >= 6) {
				method["static"] = false;
				isGenerator = eat(tt.star);
			}
			parsePropertyName(method);
			if (isDummy(method.key)) {
				if (isDummy(parseMaybeAssign())) next();
				eat(tt.comma);
				continue;
			}
			if (method.key.type == "Identifier" && !method.computed && method.key.name == "static" && (tok.type != tt.parenL && tok.type != tt.braceL)) {
				method["static"] = true;
				isGenerator = eat(tt.star);
				parsePropertyName(method);
			} else {
				method["static"] = false;
			}
			if (options.ecmaVersion >= 5 && method.key.type == "Identifier" && !method.computed && (method.key.name == "get" || method.key.name == "set") && tok.type != tt.parenL && tok.type != tt.braceL) {
				method.kind = method.key.name;
				parsePropertyName(method);
				method.value = parseMethod(false);
			} else {
				if (!method.computed && !method["static"] && !isGenerator && (method.key.type == "Identifier" && method.key.name == "constructor" || method.key.type == "Literal" && method.key.value == "constructor")) {
					method.kind = "constructor";
				} else {
					method.kind = "method";
				}
				method.value = parseMethod(isGenerator);
			}
			node.body.body.push(finishNode(method, "MethodDefinition"));
		}
		popCx();
		if (!eat(tt.braceR)) {
			this.last.end = this.tok.start;
			if (options.locations) this.last.loc.end = this.tok.loc.start;
		}
		semicolon();
		finishNode(node.body, "ClassBody");
		return finishNode(node, if (isStatement) "ClassDeclaration" else "ClassExpression");
	}

	public function parseFunction(node:FunctionDeclaration, isStatement:Bool):FunctionDeclaration {
		initFunction(node);
		if (options.ecmaVersion >= 6) node.generator = eat(tt.star);
		if (tok.type == tt.name) node.id = parseIdent();
		else if (isStatement) node.id = dummyIdent();
		node.params = parseFunctionParams();
		node.body = parseBlock();
		return finishNode(node, if (isStatement) "FunctionDeclaration" else "FunctionExpression");
	}

	public function parseExport():ExportDeclaration {
		var node = startNode();
		next();
		if (eat(tt.star)) {
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			return finishNode(node, "ExportAllDeclaration");
		}
		if (eat(tt._default)) {
			var expr = parseMaybeAssign();
			if (expr.id != null) {
				switch (expr.type) {
				case "FunctionExpression":
					expr.type = "FunctionDeclaration";
					break;
				case "ClassExpression":
					expr.type = "ClassDeclaration";
					break;
				}
			}
			node.declaration = expr;
			semicolon();
			return finishNode(node, "ExportDefaultDeclaration");
		}
		if (tok.type.keyword) {
			node.declaration = parseStatement();
			node.specifiers = new Array<ExportSpecifier>();
			node.source = null;
		} else {
			node.declaration = null;
			node.specifiers = parseExportSpecifierList();
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			semicolon();
		}
		return finishNode(node, "ExportNamedDeclaration");
	}

	public function parseImport():ImportDeclaration {
		var node = startNode();
		next();
		if (tok.type == tt.string) {
			node.specifiers = new Array<ImportSpecifier>();
			node.source = parseExprAtom();
			node.kind = "";
		} else {
			var elt:ImportSpecifier = null;
			if (tok.type == tt.name && tok.value != "from") {
				elt = startNode();
				elt.local = parseIdent();
				finishNode(elt, "ImportDefaultSpecifier");
				eat(tt.comma);
			}
			node.specifiers = parseImportSpecifierList();
			node.source = if (eatContextual("from")) parseExprAtom() else null;
			if (elt != null) node.specifiers.unshift(elt);
		}
		semicolon();
		return finishNode(node, "ImportDeclaration");
	}

	public function parseImportSpecifierList():Array<ImportSpecifier> {
		var elts = new Array<ImportSpecifier>();
		if (tok.type == tt.star) {
			var elt = startNode();
			next();
			if (eatContextual("as")) elt.local = parseIdent();
			elts.push(finishNode(elt, "ImportNamespaceSpecifier"));
		} else {
			var indent = curIndent;
			var line = curLineStart;
			var continuedLine = nextLineStart;
			pushCx();
			eat(tt.braceL);
			if (curLineStart > continuedLine) continuedLine = curLineStart;
			while (!closes(tt.braceR, indent + (if (curLineStart <= continuedLine) 1 else 0), line)) {
				var elt = startNode();
				if (eat(tt.star)) {
					if (eatContextual("as")) elt.local = parseIdent();
					finishNode(elt, "ImportNamespaceSpecifier");
				} else {
					if (isContextual("from")) break;
					elt.imported = parseIdent();
					elt.local = if (eatContextual("as")) parseIdent() else elt.imported;
					finishNode(elt, "ImportSpecifier");
				}
				elts.push(elt);
				eat(tt.comma);
			}
			eat(tt.braceR);
			popCx();
		}
		return elts;
	}

	public function parseExportSpecifierList():Array<ExportSpecifier> {
		var elts = new Array<ExportSpecifier>();
		var indent = curIndent;
		var line = curLineStart;
		var continuedLine = nextLineStart;
		pushCx();
		eat(tt.braceL);
		if (curLineStart > continuedLine) continuedLine = curLineStart;
		while (!closes(tt.braceR, indent + (if (curLineStart <= continuedLine) 1 else 0), line)) {
			if (isContextual("from")) break;
			var elt = startNode();
			elt.local = parseIdent();
			elt.exported = if (eatContextual("as")) parseIdent() else elt.local;
			finishNode(elt, "ExportSpecifier");
			elts.push(elt);
			eat(tt.comma);
		}
		eat(tt.braceR);
		popCx();
		return elts;
	}

	public function parseExpression(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var expr = parseMaybeAssign(noIn);
		if (tok.type == tt.comma) {
			var node = startNodeAt(start);
			node.expressions = new Array<Expression>();
			node.expressions.push(expr);
			while (eat(tt.comma)) node.expressions.push(parseMaybeAssign(noIn));
			return finishNode(node, "SequenceExpression");
		}
		return expr;
	}

	public function parseParenExpression():Expression {
		pushCx();
		expect(tt.parenL);
		var val = parseExpression();
		popCx();
		expect(tt.parenR);
		return val;
	}

	public function parseMaybeAssign(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var left = parseMaybeConditional(noIn);
		if (tok.type.isAssign) {
			var node = startNodeAt(start);
			node.operator = tok.value;
			node.left = if (tok.type == tt.eq) toAssignable(left) else checkLVal(left);
			next();
			node.right = parseMaybeAssign(noIn);
			return finishNode(node, "AssignmentExpression");
		}
		return left;
	}

	public function parseMaybeConditional(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var expr = parseExprOps(noIn);
		if (eat(tt.question)) {
			var node = startNodeAt(start);
			node.test = expr;
			node.consequent = parseMaybeAssign();
			node.alternate = if (expect(tt.colon)) parseMaybeAssign(noIn) else dummyIdent();
			return finishNode(node, "ConditionalExpression");
		}
		return expr;
	}

	public function parseExprOps(noIn:Bool = false):Expression {
		var start = storeCurrentPos();
		var indent = curIndent;
		var line = curLineStart;
		return parseExprOp(parseMaybeUnary(noIn), start, -1, noIn, indent, line);
	}

	public function parseExprOp(left:Expression, start:Array<Int>, minPrec:Int, noIn:Bool, indent:Int, line:Int):Expression {
		if (curLineStart != line && curIndent < indent && tokenStartsLine()) return left;
		var prec = tok.type.binop;
		if (prec != null && (!noIn || tok.type != tt._in)) {
			if (prec > minPrec) {
				var node = startNodeAt(start);
				node.left = left;
				node.operator = tok.value;
				next();
				if (curLineStart != line && curIndent < indent && tokenStartsLine()) {
					node.right = dummyIdent();
				} else {
					var rightStart = storeCurrentPos();
					node.right = parseExprOp(parseMaybeUnary(noIn), rightStart, prec, noIn, indent, line);
				}
				this.finishNode(node, if (/"&&"|"||"/.match(node.operator) != null) "LogicalExpression" else "BinaryExpression");
				return parseExprOp(node, start, minPrec, noIn, indent, line);
			}
		}
		return left;
	}

	public function parseMaybeUnary(noIn:Bool = false):Expression {
		if (tok.type.prefix) {
			var node = startNode();
			var update = tok.type == tt.incDec;
			node.operator = tok.value;
			node.prefix = true;
			next();
			node.argument = parseMaybeUnary(noIn);
			if (update) node.argument = checkLVal(node.argument);
			return finishNode(node, if (update) "UpdateExpression" else "UnaryExpression");
		} else if (tok.type == tt.ellipsis) {
			var node = startNode();
			next();
			node.argument = parseMaybeUnary(noIn);
			return finishNode(node, "SpreadElement");
		}
		var start = storeCurrentPos();
		var expr = parseExprSubscripts();
		while (tok.type.postfix && !canInsertSemicolon()) {
			var node = startNodeAt(start);
			node.operator = tok.value;
			node.prefix = false;
			node.argument = checkLVal(expr);
			next();
			expr = finishNode(node, "UpdateExpression");
		}
		return expr;
	}

	public function parseExprSubscripts():Expression {
		var start = storeCurrentPos();
		return parseSubscripts(parseExprAtom(), start, false, curIndent, curLineStart);
	}

	public function parseSubscripts(base:Expression, start:Array<Int>, noCalls:Bool, startIndent:Int, line:Int):Expression {
		while (true) {
			if (curLineStart != line && curIndent <= startIndent && tokenStartsLine()) {
				if (tok.type == tt.dot && curIndent == startIndent) --startIndent;
				else return base;
			}
			if (eat(tt.dot)) {
				var node = startNodeAt(start);
				node.object = base;
				if (curLineStart != line && curIndent <= startIndent && tokenStartsLine()) node.property = dummyIdent();
				else node.property = parsePropertyAccessor() || dummyIdent();
				node.computed = false;
				base = finishNode(node, "MemberExpression");
			} else if (tok.type == tt.bracketL) {
				pushCx();
				next();
				var node = startNodeAt(start);
				node.object = base;
				node.property = parseExpression();
				node.computed = true;
				popCx();
				expect(tt.bracketR);
				base = finishNode(node, "MemberExpression");
			} else if (!noCalls && tok.type == tt.parenL) {
				pushCx();
				var node = startNodeAt(start);
				node.callee = base;
				node.arguments = parseExprList(tt.parenR);
				base = finishNode(node, "CallExpression");
			} else if (tok.type == tt.backQuote) {
				var node = startNodeAt(start);
				node.tag = base;
				node.quasi = parseTemplate();
				base = finishNode(node, "TaggedTemplateExpression");
			} else {
				return base;
			}
		}
	}

	public function parseExprAtom():Expression {
		var node:Expression = null;
		switch (tok.type) {
		case tt._this:
		case tt._super:
			var type = if (tok.type == tt._this) "ThisExpression" else "Super";
			node = startNode();
			next();
			return finishNode(node, type);
		case tt.name:
			var start = storeCurrentPos();
			var id = parseIdent();
			return if (eat(tt.arrow)) parseArrowExpression(startNodeAt(start), [id]) else id;
		case tt.regexp:
			node = startNode();
			var val = tok.value;
			node.regex = { pattern: val.pattern, flags: val.flags };
			node.value = val.value;
			node.raw = input.substr(tok.start, tok.end);
			next();
			return finishNode(node, "Literal");
		case tt.num:
		case tt.string:
			node = startNode();
			node.value = tok.value;
			node.raw = input.substr(tok.start, tok.end);
			next();
			return finishNode(node, "Literal");
		case tt._null:
		case tt._true:
		case tt._false:
			node = startNode();
			node.value = if (tok.type == tt._null) null else if (tok.type == tt._true) true else false;
			node.raw = tok.type.keyword;
			next();
			return finishNode(node, "Literal");
		case tt.parenL:
			var parenStart = storeCurrentPos();
			next();
			var inner = parseExpression();
			expect(tt.parenR);
			if (eat(tt.arrow)) {
				return parseArrowExpression(startNodeAt(parenStart), if (inner.expressions != null) inner.expressions else if (isDummy(inner)) new Array<Expression>() else new Array<Expression>(inner));
			}
			if (options.preserveParens) {
				var par = startNodeAt(parenStart);
				par.expression = inner;
				inner = finishNode(par, "ParenthesizedExpression");
			}
			return inner;
		case tt.bracketL:
			node = startNode();
			pushCx();
			node.elements = parseExprList(tt.bracketR, true);
			return finishNode(node, "ArrayExpression");
		case tt.braceL:
			return parseObj();
		case tt._class:
			return parseClass(false);
		case tt._function:
			node = startNode();
			next();
			return parseFunction(node, false);
		case tt._new:
			return parseNew();
		case tt._yield:
			node = startNode();
			next();
			if (semicolon() || canInsertSemicolon() || (tok.type != tt.star && !tok.type.startsExpr)) {
				node.delegate = false;
				node.argument = null;
			} else {
				node.delegate = eat(tt.star);
				node.argument = parseMaybeAssign();
			}
			return finishNode(node, "YieldExpression");
		case tt.backQuote:
			return parseTemplate();
		default:
			return dummyIdent();
		}
	}

	public function parseNew():NewExpression {
		var node = startNode();
		var startIndent = curIndent;
		var line = curLineStart;
		var meta = parseIdent(true);
		if (options.ecmaVersion >= 6 && eat(tt.dot)) {
			node.meta = meta;
			node.property = parseIdent(true);
			return finishNode(node, "MetaProperty");
		}
		var start = storeCurrentPos();
		node.callee = parseSubscripts(parseExprAtom(), start, true, startIndent, line);
		if (tok.type == tt.parenL) {
			pushCx();
			node.arguments = parseExprList(tt.parenR);
		} else {
			node.arguments = new Array<Expression>();
		}
		return finishNode(node, "NewExpression");
	}

	public function parseTemplateElement():TemplateElement {
		var elem = startNode();
		elem.value = { raw: input.substr(tok.start, tok.end), cooked: tok.value };
		next();
		elem.tail = tok.type == tt.backQuote;
		return finishNode(elem, "TemplateElement");
	}

	public function parseTemplate():TemplateLiteral {
		var node = startNode();
		next();
		node.expressions = new Array<Expression>();
		var curElt = parseTemplateElement();
		node.quasis = new Array<TemplateElement>();
		node.quasis.push(curElt);
		while (!curElt.tail) {
			next();
			node.expressions.push(parseExpression());
			if (expect(tt.braceR)) {
				curElt = parseTemplateElement();
			} else {
				curElt = startNode();
				curElt.value = { cooked: "", raw: "" };
				curElt.tail = true;
			}
			node.quasis.push(curElt);
		}
		expect(tt.backQuote);
		return finishNode(node, "TemplateLiteral");
	}

	public function parseObj():ObjectExpression {
		var node = startNode();
		node.properties = new Array<Property>();
		pushCx();
		var indent = curIndent + 1;
		var line = curLineStart;
		eat(tt.braceL);
		if (curIndent + 1 < indent) {
			indent = curIndent;
			line = curLineStart;
		}
		while (!closes(tt.braceR, indent, line)) {
			var prop = startNode();
			var isGenerator:Bool = false;
			var start:Array<Int> = null;
			if (options.ecmaVersion >= 6) {
				start = storeCurrentPos();
				prop.method = false;
				prop.shorthand = false;
				isGenerator = eat(tt.star);
			}
			parsePropertyName(prop);
			if (isDummy(prop.key)) {
				if (isDummy(parseMaybeAssign())) next();
				eat(tt.comma);
				continue;
			}
			if (eat(tt.colon)) {
				prop.kind = "init";
				prop.value = parseMaybeAssign();
			} else if (options.ecmaVersion >= 6 && (tok.type == tt.parenL || tok.type == tt.braceL)) {
				prop.kind = "init";
				prop.method = true;
				prop.value = parseMethod(isGenerator);
			} else if (options.ecmaVersion >= 5 && prop.key.type == "Identifier" && !prop.computed && (prop.key.name == "get" || prop.key.name == "set") && (tok.type != tt.comma && tok.type != tt.braceR)) {
				prop.kind = prop.key.name;
				parsePropertyName(prop);
				prop.value = parseMethod(false);
			} else {
				prop.kind = "init";
				if (options.ecmaVersion >= 6) {
					if (eat(tt.eq)) {
						var assign = startNodeAt(start);
						assign.operator = "=";
						assign.left = prop.key;
						assign.right = parseMaybeAssign();
						prop.value = finishNode(assign, "AssignmentExpression");
					} else {
						prop.value = prop.key;
					}
				} else {
					prop.value = dummyIdent();
				}
				prop.shorthand = true;
			}
			node.properties.push(finishNode(prop, "Property"));
			eat(tt.comma);
		}
		popCx();
		if (!eat(tt.braceR)) {
			this.last.end = this.tok.start;
			if (options.locations) this.last.loc.end = this.tok.loc.start;
		}
		return finishNode(node, "ObjectExpression");
	}

	public function parsePropertyName(prop:Property) {
		if (options.ecmaVersion >= 6) {
			if (eat(tt.bracketL)) {
				prop.computed = true;
				prop.key = parseExpression();
				expect(tt.bracketR);
				return;
			} else {
				prop.computed = false;
			}
		}
		var key = if (tok.type == tt.num || tok.type == tt.string) parseExprAtom() else parseIdent();
		prop.key = if (key != null) key else dummyIdent();
	}

	public function parsePropertyAccessor():Expression {
		if (tok.type == tt.name || tok.type.keyword) return parseIdent();
		return null;
	}

	public function parseIdent(isMeta:Bool = false):Identifier {
		var name = if (tok.type == tt.name) tok.value else tok.type.keyword;
		if (name == null) return dummyIdent();
		var node = startNode();
		next();
		node.name = name;
		return finishNode(node, "Identifier");
	}

	public function initFunction(node:Function) {
		node.id = null;
		node.params = new Array<Pattern>();
		if (options.ecmaVersion >= 6) {
			node.generator = false;
			node.expression = false;
		}
	}

	public