import three.REVISION;
import ast.AST;
import nodes.Nodes;

class TSLEncoder {

	public var tab:String = "";
	public var imports:Set<String> = new Set();
	public var global:Set<String> = new Set();
	public var overloadings:Map<String, Array<AST.FunctionDeclaration>> = new Map();
	public var layoutsCode:String = "";
	public var iife:Bool = false;
	public var uniqueNames:Bool = false;
	public var reference:Bool = false;

	private var _currentProperties:Map<String, Dynamic> = new Map();
	private var _lastStatement:Dynamic = null;

	public function new() {
	}

	public function addImport(name:String) {
		name = name.split(".").get(0);
		if (Nodes.hasOwnProperty(name) && !global.has(name) && !_currentProperties.exists(name)) {
			imports.add(name);
		}
	}

	public function emitUniform(node:AST.Uniform):String {
		var code:String = "const ${node.name} = ";
		if (reference) {
			addImport("reference");
			global.add(node.name);
			//code += `reference( '${ node.name }', '${ node.type }', uniforms )`;

			// legacy
			code += `reference( 'value', '${node.type}', uniforms['${node.name}'] )`;
		} else {
			addImport("uniform");
			global.add(node.name);
			code += `uniform( '${node.type}' )`;
		}
		return code;
	}

	public function emitExpression(node:Dynamic):String {
		var code:String;

		/*@TODO: else if ( node.isVarying ) {

			code = this.emitVarying( node );

		}*/

		if (Std.is(node, AST.Accessor)) {
			addImport(node.property);
			code = node.property;
		} else if (Std.is(node, AST.Number)) {
			if (node.type == "int" || node.type == "uint") {
				code = "${node.type}( ${node.value} )";
				addImport(node.type);
			} else {
				code = node.value;
			}
		} else if (Std.is(node, AST.String)) {
			code = "'${node.value}'";
		} else if (Std.is(node, AST.Operator)) {
			var opFn:String = opLib.get(node.type) || node.type;
			var left:String = emitExpression(node.left);
			var right:String = emitExpression(node.right);

			if (isPrimitive(left) && isPrimitive(right)) {
				return "${left} ${node.type} ${right}";
			}

			if (isPrimitive(left)) {
				code = "${opFn}( ${left}, ${right} )";
				addImport(opFn);
			} else {
				code = "${left}.${opFn}( ${right} )";
			}
		} else if (Std.is(node, AST.FunctionCall)) {
			var params:Array<String> = [];
			for (param in node.params) {
				params.push(emitExpression(param));
			}
			addImport(node.name);
			var paramsStr:String = params.length > 0 ? " " + params.join(", ") + " " : "";
			code = `${node.name}(${paramsStr})`;
		} else if (Std.is(node, AST.Return)) {
			code = "return";
			if (node.value != null) {
				code += " " + emitExpression(node.value);
			}
		} else if (Std.is(node, AST.AccessorElements)) {
			code = node.property;
			for (element in node.elements) {
				if (Std.is(element, AST.StaticElement)) {
					code += ".${emitExpression(element.value)}";
				} else if (Std.is(element, AST.DynamicElement)) {
					var value:String = emitExpression(element.value);
					if (isPrimitive(value)) {
						code += `[ ${value} ]`;
					} else {
						code += `.element( ${value} )`;
					}
				}
			}
		} else if (Std.is(node, AST.DynamicElement)) {
			code = emitExpression(node.value);
		} else if (Std.is(node, AST.StaticElement)) {
			code = emitExpression(node.value);
		} else if (Std.is(node, AST.For)) {
			code = emitFor(node);
		} else if (Std.is(node, AST.VariableDeclaration)) {
			code = emitVariables(node);
		} else if (Std.is(node, AST.Uniform)) {
			code = emitUniform(node);
		} else if (Std.is(node, AST.Ternary)) {
			code = emitTernary(node);
		} else if (Std.is(node, AST.Conditional)) {
			code = emitConditional(node);
		} else if (Std.is(node, AST.Unary) && Std.is(node.expression, AST.Number)) {
			code = "${node.type} ${node.expression.value}";
		} else if (Std.is(node, AST.Unary)) {
			var type:String = unaryLib.get(node.type) || "";
			if (node.after == false && (node.type == "++" || node.type == "--")) {
				type += "Before";
			}
			var exp:String = emitExpression(node.expression);
			if (isPrimitive(exp)) {
				addImport(type);
				code = "${type}( ${exp} )";
			} else {
				code = "${exp}.${type}()";
			}
		} else {
			Sys.println("Unknown node type: " + node);
		}

		if (code == null) code = "/* unknown statement */";
		return code;
	}

	public function emitBody(body:Array<Dynamic>):String {
		setLastStatement(null);
		var code:String = "";
		tab += "\t";
		for (statement in body) {
			code += emitExtraLine(statement);
			code += tab + emitExpression(statement);
			if (code.substring(code.length - 1) != "}") code += ";";
			code += "\n";
			setLastStatement(statement);
		}
		code = code.substring(0, code.length - 1); // remove the last extra line
		tab = tab.substring(0, tab.length - 1);
		return code;
	}

	public function emitTernary(node:AST.Ternary):String {
		var condStr:String = emitExpression(node.cond);
		var leftStr:String = emitExpression(node.left);
		var rightStr:String = emitExpression(node.right);
		addImport("cond");
		return `cond( ${condStr}, ${leftStr}, ${rightStr} )`;
	}

	public function emitConditional(node:AST.Conditional):String {
		var condStr:String = emitExpression(node.cond);
		var bodyStr:String = emitBody(node.body);
		var ifStr:String = `If( ${condStr}, () => {

${bodyStr}

${tab}} )`;
		var current:AST.Conditional = node;
		while (current.elseConditional != null) {
			var elseBodyStr:String = emitBody(current.elseConditional.body);
			if (current.elseConditional.cond != null) {
				var elseCondStr:String = emitExpression(current.elseConditional.cond);
				ifStr += `.elseif( ${elseCondStr}, () => {

${elseBodyStr}

${tab}} )`;
			} else {
				ifStr += `.else( () => {

${elseBodyStr}

${tab}} )`;
			}
			current = current.elseConditional;
		}
		imports.add("If");
		return ifStr;
	}

	public function emitLoop(node:AST.For):String {
		var start:String = emitExpression(node.initialization.value);
		var end:String = emitExpression(node.condition.right);
		var name:String = node.initialization.name;
		var type:String = node.initialization.type;
		var condition:String = node.condition.type;
		var update:String = node.afterthought.type;
		var nameParam:String = name != "i" ? ", name: '${name}'" : "";
		var typeParam:String = type != "int" ? ", type: '${type}'" : "";
		var conditionParam:String = condition != "<" ? ", condition: '${condition}'" : "";
		var updateParam:String = update != "++" ? ", update: '${update}'" : "";
		var loopStr:String = `loop( { start: ${start}, end: ${end + nameParam + typeParam + conditionParam + updateParam} }, ( { ${name} } ) => {\n\n`;
		loopStr += emitBody(node.body) + "\n\n";
		loopStr += tab + "} )";
		imports.add("loop");
		return loopStr;
	}

	public function emitFor(node:AST.For):String {
		if ((node.initialization != null && Std.is(node.initialization, AST.VariableDeclaration) && node.initialization.next == null) &&
			(node.condition != null && Std.is(node.condition.left, AST.Accessor) && node.condition.left.property == node.initialization.name) &&
			(node.afterthought != null && Std.is(node.afterthought, AST.Unary)) &&
			(node.initialization.name == node.afterthought.expression.property)) {
			return emitLoop(node);
		}
		return emitForWhile(node);
	}

	public function emitForWhile(node:AST.For):String {
		var initialization:String = emitExpression(node.initialization);
		var condition:String = emitExpression(node.condition);
		var afterthought:String = emitExpression(node.afterthought);
		tab += "\t";
		var forStr:String = "{\n\n" + tab + initialization + ";\n\n";
		forStr += `${tab}While( ${condition}, () => {\n\n`;
		forStr += emitBody(node.body) + "\n\n";
		forStr += tab + "\t" + afterthought + ";\n\n";
		forStr += tab + "} )\n\n";
		tab = tab.substring(0, tab.length - 1);
		forStr += tab + "}";
		imports.add("While");
		return forStr;
	}

	public function emitVariables(node:AST.VariableDeclaration, isRoot:Bool = true):String {
		var name:String = node.name;
		var type:String = node.type;
		var value:Dynamic = node.value;
		var next:AST.VariableDeclaration = node.next;
		var valueStr:String = value != null ? emitExpression(value) : "";
		var varStr:String = isRoot ? "const " : "";
		varStr += name;
		if (value != null) {
			if (Std.is(value, AST.FunctionCall) && value.name == type) {
				varStr += " = " + valueStr;
			} else {
				varStr += ` = ${type}( ${valueStr} )`;
			}
		} else {
			varStr += ` = ${type}()`;
		}
		if (node.immutable == false) {
			varStr += ".toVar()";
		}
		if (next != null) {
			varStr += ", " + emitVariables(next, false);
		}
		addImport(type);
		return varStr;
	}

	/*emitVarying( node ) { }*/

	public function emitOverloadingFunction(nodes:Array<AST.FunctionDeclaration>):String {
		var name:String = nodes.get(0).name;
		addImport("overloadingFn");
		return `const ${name} = overloadingFn( [ ${nodes.map(node => node.name + "_" + nodes.indexOf(node)).join(", ")} ] );\n`;
	}

	public function emitFunction(node:AST.FunctionDeclaration):String {
		var name:String = node.name;
		var type:String = node.type;
		_currentProperties = new Map();
		_currentProperties.set(name, node);
		var params:Array<String> = [];
		var inputs:Array<String> = [];
		var mutableParams:Array<AST.FunctionParameter> = [];
		var hasPointer:Bool = false;
		for (param in node.params) {
			var str:String = `{ name: '${param.name}', type: '${param.type}'`;
			var name:String = param.name;
			if (param.immutable == false && (param.qualifier != "inout" && param.qualifier != "out")) {
				name = name + "_immutable";
				mutableParams.push(param);
			}
			if (param.qualifier != null) {
				if (param.qualifier == "inout" || param.qualifier == "out") {
					hasPointer = true;
				}
				str += ", qualifier: '" + param.qualifier + "'";
			}
			inputs.push(str + " }");
			params.push(name);
			_currentProperties.set(name, param);
		}
		for (param in mutableParams) {
			node.body.unshift(new AST.VariableDeclaration(param.type, param.name, new AST.Accessor(param.name + "_immutable")));
		}
		var paramsStr:String = params.length > 0 ? " [ " + params.join(", ") + " ] " : "";
		var bodyStr:String = emitBody(node.body);
		var fnName:String = name;
		var overloadingNodes:Array<AST.FunctionDeclaration> = null;
		if (overloadings.exists(name)) {
			var overloadings:Array<AST.FunctionDeclaration> = overloadings.get(name);
			if (overloadings.length > 1) {
				var index:Int = overloadings.indexOf(node);
				fnName += "_" + index;
				if (index == overloadings.length - 1) {
					overloadingNodes = overloadings;
				}
			}
		}
		var funcStr:String = `const ${fnName} = tslFn( (${paramsStr}) => {

${bodyStr}

${tab}} );\n`;
		var layoutInput:String = inputs.length > 0 ? "\n\t\t" + tab + inputs.join(",\n\t\t" + tab) + "\n\t" + tab : "";
		if (node.layout != false && hasPointer == false) {
			var uniqueName:String = uniqueNames ? fnName + "_" + Math.random().toString(36).slice(2) : fnName;
			layoutsCode += `${tab + fnName}.setLayout( {
${tab}\tname: '${uniqueName}',
${tab}\ttype: '${type}',
${tab}\tinputs: [${layoutInput}]
${tab}} );\n\n`;
		}
		imports.add("tslFn");
		global.add(node.name);
		if (overloadingNodes != null) {
			funcStr += "\n" + emitOverloadingFunction(overloadingNodes);
		}
		return funcStr;
	}

	public function setLastStatement(statement:Dynamic) {
		_lastStatement = statement;
	}

	public function emitExtraLine(statement:Dynamic):String {
		var last:Dynamic = _lastStatement;
		if (last == null) return "";
		if (Std.is(statement, AST.Return)) return "\n";
		var isExpression:Dynamic = (st:Dynamic) -> Bool {
			return !Std.is(st, AST.FunctionDeclaration) && !Std.is(st, AST.For) && !Std.is(st, AST.Conditional);
		};
		var lastExp:Bool = isExpression(last);
		var currExp:Bool = isExpression(statement);
		if (lastExp != currExp || (!lastExp && !currExp)) return "\n";
		return "";
	}

	public function emit(ast:AST.Program):String {
		var code:String = "\n";
		if (iife) tab += "\t";
		var overloadings:Map<String, Array<AST.FunctionDeclaration>> = new Map();
		for (statement in ast.body) {
			if (Std.is(statement, AST.FunctionDeclaration)) {
				if (!overloadings.exists(statement.name)) {
					overloadings.set(statement.name, []);
				}
				overloadings.get(statement.name).push(statement);
			}
		}
		for (statement in ast.body) {
			code += emitExtraLine(statement);
			if (Std.is(statement, AST.FunctionDeclaration)) {
				code += tab + emitFunction(statement);
			} else {
				code += tab + emitExpression(statement) + ";\n";
			}
			setLastStatement(statement);
		}
		var imports:Array<String> = [...this.imports];
		var exports:Array<String> = [...this.global];
		var layouts:String = layoutsCode.length > 0 ? `\n${tab}// layouts\n\n` + layoutsCode : "";
		var header:String = "// Three.js Transpiler r" + REVISION + "\n\n";
		var footer:String = "";
		if (iife) {
			header += "( function ( TSL, uniforms ) {\n\n";
			header += imports.length > 0 ? "\tconst { " + imports.join(", ") + " } = TSL;\n" : "";
			footer += exports.length > 0 ? "\treturn { " + exports.join(", ") + " };\n" : "";
			footer += "\n} );";
		} else {
			header += imports.length > 0 ? "import { " + imports.join(", ") + " } from 'three/nodes';\n" : "";
			footer += exports.length > 0 ? "export { " + exports.join(", ") + " };\n" : "";
		}
		return header + code + layouts + footer;
	}

}

private var opLib:Map<String, String> = new Map([
	("=", "assign"),
	("+", "add"),
	("-", "sub"),
	("*", "mul"),
	("/", "div"),
	("%", "remainder"),
	("<", "lessThan"),
	(">", "greaterThan"),
	("<=", "lessThanEqual"),
	(">=", "greaterThanEqual"),
	("==", "equal"),
	("&&", "and"),
	("||", "or"),
	("^^", "xor"),
	("&", "bitAnd"),
	("|", "bitOr"),
	("^", "bitXor"),
	("<<", "shiftLeft"),
	(">>", "shiftRight"),
	("+=", "addAssign"),
	("-=", "subAssign"),
	("*=", "mulAssign"),
	("/=", "divAssign"),
	("%=", "remainderAssign"),
	("^=", "bitXorAssign"),
	("&= ", "bitAndAssign"),
	("|= ", "bitOrAssign"),
	("<<=", "shiftLeftAssign"),
	(">>>=", "shiftRightAssign")
]);

private var unaryLib:Map<String, String> = new Map([
	("+", ""), // positive
	("-", "negate"),
	("~", "bitNot"),
	("!", "not"),
	("++", "increment"), // incrementBefore
	("--", "decrement") // decrementBefore
]);

private function isPrimitive(value:String):Bool {
	return value.match(/^(true|false|-?\d)/) != null;
}