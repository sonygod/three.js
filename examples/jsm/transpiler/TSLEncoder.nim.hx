import three.REVISION;
import three.nodes.VariableDeclaration;
import three.nodes.Accessor;
import three.nodes.*;

class OpLib {
	public static var opLib:haxe.ds.StringMap<String> = new haxe.ds.StringMap<String>();
	static {
		opLib.set("=", "assign");
		opLib.set("+", "add");
		opLib.set("-", "sub");
		opLib.set("*", "mul");
		opLib.set("/", "div");
		opLib.set("%", "remainder");
		opLib.set("<", "lessThan");
		opLib.set(">", "greaterThan");
		opLib.set("<=", "lessThanEqual");
		opLib.set(">=", "greaterThanEqual");
		opLib.set("==", "equal");
		opLib.set("&&", "and");
		opLib.set("||", "or");
		opLib.set("^^", "xor");
		opLib.set("&", "bitAnd");
		opLib.set("|", "bitOr");
		opLib.set("^", "bitXor");
		opLib.set("<<", "shiftLeft");
		opLib.set(">>", "shiftRight");
		opLib.set("+=", "addAssign");
		opLib.set("-=", "subAssign");
		opLib.set("*=", "mulAssign");
		opLib.set("/=", "divAssign");
		opLib.set("%=", "remainderAssign");
		opLib.set("^=", "bitXorAssign");
		opLib.set("&=", "bitAndAssign");
		opLib.set("|=", "bitOrAssign");
		opLib.set("<<=", "shiftLeftAssign");
		opLib.set(">>=", "shiftRightAssign");
	}
}

class UnaryLib {
	public static var unaryLib:haxe.ds.StringMap<String> = new haxe.ds.StringMap<String>();
	static {
		unaryLib.set("+", ""); // positive
		unaryLib.set("-", "negate");
		unaryLib.set("~", "bitNot");
		unaryLib.set("!", "not");
		unaryLib.set("++", "increment"); // incrementBefore
		unaryLib.set("--", "decrement"); // decrementBefore
	}
}

class TSLEncoder {

	public var tab:String;
	public var imports:haxe.ds.StringSet;
	public var global:haxe.ds.StringSet;
	public var overloadings:haxe.ds.StringMap<Array<Dynamic>>;
	public var layoutsCode:String;
	public var iife:Bool;
	public var uniqueNames:Bool;
	public var reference:Bool;

	public var _currentProperties:haxe.ds.StringMap<Dynamic>;
	public var _lastStatement:Dynamic;

	public function new() {
		this.tab = '';
		this.imports = new haxe.ds.StringSet();
		this.global = new haxe.ds.StringSet();
		this.overloadings = new haxe.ds.StringMap<Array<Dynamic>>();
		this.layoutsCode = '';
		this.iife = false;
		this.uniqueNames = false;
		this.reference = false;

		this._currentProperties = new haxe.ds.StringMap<Dynamic>();
		this._lastStatement = null;
	}

	public function addImport(name:String) {
		name = name.split('.').shift();
		if (three.nodes[name] !== null && this.global.exists(name) === false && this._currentProperties[name] === null) {
			this.imports.add(name);
		}
	}

	public function emitUniform(node:Dynamic) {
		var code = 'const ' + node.name + ' = ';
		if (this.reference === true) {
			this.addImport('reference');
			this.global.add(node.name);
			//code += `reference( '${ node.name }', '${ node.type }', uniforms )`;
			// legacy
			code += 'reference( \'value\', \'' + node.type + '\', uniforms[ \'' + node.name + '\' ] )';
		} else {
			this.addImport('uniform');
			this.global.add(node.name);
			code += 'uniform( \'' + node.type + '\' )';
		}
		return code;
	}

	public function emitExpression(node:Dynamic):String {
		var code:String;
		/*@TODO: else if ( node.isVarying ) {
			code = this.emitVarying( node );
		}*/
		if (node.isAccessor) {
			this.addImport(node.property);
			code = node.property;
		} else if (node.isNumber) {
			if (node.type === 'int' || node.type === 'uint') {
				code = node.type + '( ' + node.value + ' )';
				this.addImport(node.type);
			} else {
				code = node.value;
			}
		} else if (node.isString) {
			code = '\'' + node.value + '\'';
		} else if (node.isOperator) {
			var opFn = OpLib.opLib.get(node.type) || node.type;
			var left = this.emitExpression(node.left);
			var right = this.emitExpression(node.right);
			if (isPrimitive(left) && isPrimitive(right)) {
				return left + ' ' + node.type + ' ' + right;
			}
			if (isPrimitive(left)) {
				code = opFn + '( ' + left + ', ' + right + ' )';
				this.addImport(opFn);
			} else {
				code = left + '.' + opFn + '( ' + right + ' )';
			}
		} else if (node.isFunctionCall) {
			var params = [];
			for (param in node.params) {
				params.push(this.emitExpression(param));
			}
			this.addImport(node.name);
			var paramsStr = params.length > 0 ? ' ' + params.join(', ') + ' ' : '';
			code = node.name + '(' + paramsStr + ')';
		} else if (node.isReturn) {
			code = 'return';
			if (node.value) {
				code += ' ' + this.emitExpression(node.value);
			}
		} else if (node.isAccessorElements) {
			code = node.property;
			for (element in node.elements) {
				if (element.isStaticElement) {
					code += '.' + this.emitExpression(element.value);
				} else if (element.isDynamicElement) {
					var value = this.emitExpression(element.value);
					if (isPrimitive(value)) {
						code += '[' + value + ']';
					} else {
						code += '.element( ' + value + ' )';
					}
				}
			}
		} else if (node.isDynamicElement) {
			code = this.emitExpression(node.value);
		} else if (node.isStaticElement) {
			code = this.emitExpression(node.value);
		} else if (node.isFor) {
			code = this.emitFor(node);
		} else if (node.isVariableDeclaration) {
			code = this.emitVariables(node);
		} else if (node.isUniform) {
			code = this.emitUniform(node);
		} else if (node.isTernary) {
			code = this.emitTernary(node);
		} else if (node.isConditional) {
			code = this.emitConditional(node);
		} else if (node.isUnary && node.expression.isNumber) {
			code = node.type + ' ' + node.expression.value;
		} else if (node.isUnary) {
			var type = UnaryLib.unaryLib.get(node.type);
			if (node.after === false && (node.type === '++' || node.type === '--')) {
				type += 'Before';
			}
			var exp = this.emitExpression(node.expression);
			if (isPrimitive(exp)) {
				this.addImport(type);
				code = type + '( ' + exp + ' )';
			} else {
				code = exp + '.' + type + '()';
			}
		} else {
			trace('Unknown node type', node);
		}
		if (!code) code = '/* unknown statement */';
		return code;
	}

	public function emitBody(body:Array<Dynamic>):String {
		this.setLastStatement(null);
		var code = '';
		this.tab += '\t';
		for (statement in body) {
			code += this.emitExtraLine(statement);
			code += this.tab + this.emitExpression(statement);
			if (code.slice(-1) !== '}') code += ';';
			code += '\n';
			this.setLastStatement(statement);
		}
		code = code.slice(0, -1); // remove the last extra line
		this.tab = this.tab.slice(0, -1);
		return code;
	}

	public function emitTernary(node:Dynamic):String {
		var condStr = this.emitExpression(node.cond);
		var leftStr = this.emitExpression(node.left);
		var rightStr = this.emitExpression(node.right);
		this.addImport('cond');
		return 'cond( ' + condStr + ', ' + leftStr + ', ' + rightStr + ' )';
	}

	public function emitConditional(node:Dynamic):String {
		var condStr = this.emitExpression(node.cond);
		var bodyStr = this.emitBody(node.body);
		var ifStr = 'If( ' + condStr + ', () => {\n\n' + this.tab + bodyStr + '\n\n' + this.tab + '} )';
		var current = node;
		while (current.elseConditional) {
			var elseBodyStr = this.emitBody(current.elseConditional.body);
			if (current.elseConditional.cond) {
				var elseCondStr = this.emitExpression(current.elseConditional.cond);
				ifStr += '.elseif( ' + elseCondStr + ', () => {\n\n' + this.tab + elseBodyStr + '\n\n' + this.tab + '} )';
			} else {
				ifStr += '.else( () => {\n\n' + this.tab + elseBodyStr + '\n\n' + this.tab + '} )';
			}
			current = current.elseConditional;
		}
		this.imports.add('If');
		return ifStr;
	}

	public function emitLoop(node:Dynamic):String {
		var start = this.emitExpression(node.initialization.value);
		var end = this.emitExpression(node.condition.right);
		var name = node.initialization.name;
		var type = node.initialization.type;
		var condition = node.condition.type;
		var update = node.afterthought.type;
		var nameParam = name !== 'i' ? ', name: \'' + name + '\'' : '';
		var typeParam = type !== 'int' ? ', type: \'' + type + '\'' : '';
		var conditionParam = condition !== '<' ? ', condition: \'' + condition + '\'' : '';
		var updateParam = update !== '++' ? ', update: \'' + update + '\'' : '';
		var loopStr = 'loop( { start: ' + start + ', end: ' + end + nameParam + typeParam + conditionParam + updateParam + ' }, ( { ' + name + ' } ) => {\n\n';
		loopStr += this.emitBody(node.body) + '\n\n';
		loopStr += this.tab + '} )';
		this.imports.add('loop');
		return loopStr;
	}

	public function emitFor(node:Dynamic):String {
		var { initialization, condition, afterthought } = node;
		if ((initialization && initialization.isVariableDeclaration && initialization.next === null) && (condition && condition.left.isAccessor && condition.left.property === initialization.name) && (afterthought && afterthought.isUnary) && (initialization.name === afterthought.expression.property)) {
			return this.emitLoop(node);
		}
		return this.emitForWhile(node);
	}

	public function emitForWhile(node:Dynamic):String {
		var initialization = this.emitExpression(node.initialization);
		var condition = this.emitExpression(node.condition);
		var afterthought = this.emitExpression(node.afterthought);
		this.tab += '\t';
		var forStr = '{\n\n' + this.tab + initialization + ';\n\n';
		forStr += this.tab + 'While( ' + condition + ', () => {\n\n';
		forStr += this.emitBody(node.body) + '\n\n';
		forStr += this.tab + '\t' + afterthought + ';\n\n';
		forStr += this.tab + '} )\n\n';
		this.tab = this.tab.slice(0, -1);
		forStr += this.tab + '}';
		this.imports.add('While');
		return forStr;
	}

	public function emitVariables(node:Dynamic, isRoot:Bool = true):String {
		var { name, type, value, next } = node;
		var valueStr = value ? this.emitExpression(value) : '';
		var varStr = isRoot ? 'const ' : '';
		varStr += name;
		if (value) {
			if (value.isFunctionCall && value.name === type) {
				varStr += ' = ' + valueStr;
			} else {
				varStr += ' = ' + type + '( ' + valueStr + ' )';
			}
		} else {
			varStr += ' = ' + type + '()';
		}
		if (node.immutable === false) {
			varStr += '.toVar()';
		}
		if (next) {
			varStr += ', ' + this.emitVariables(next, false);
		}
		this.addImport(type);
		return varStr;
	}

	/*public function emitVarying(node:Dynamic):String { }*/

	public function emitOverloadingFunction(nodes:Array<Dynamic>):String {
		var { name } = nodes[0];
		this.addImport('overloadingFn');
		return 'const ' + name + ' = overloadingFn( [ ' + nodes.map(node => node.name + '_' + nodes.indexOf(node)).join(', ') + ' ] );\n';
	}

	public function emitFunction(node:Dynamic):String {
		var { name, type } = node;
		this._currentProperties = { name: node };
		var params = [];
		var inputs = [];
		var mutableParams = [];
		var hasPointer = false;
		for (param in node.params) {
			var str = '{ name: \'' + param.name + '\', type: \'' + param.type + '\'';
			var name = param.name;
			if (param.immutable === false && (param.qualifier !== 'inout' && param.qualifier !== 'out')) {
				name = name + '_immutable';
				mutableParams.push(param);
			}
			if (param.qualifier) {
				if (param.qualifier === 'inout' || param.qualifier === 'out') {
					hasPointer = true;
				}
				str += ', qualifier: \'' + param.qualifier + '\'';
			}
			inputs.push(str + ' }');
			params.push(name);
			this._currentProperties[name] = param;
		}
		for (param in mutableParams) {
			node.body.unshift(new VariableDeclaration(param.type, param.name, new Accessor(param.name + '_immutable')));
		}
		var paramsStr = params.length > 0 ? ' [ ' + params.join(', ') + ' ] ' : '';
		var bodyStr = this.emitBody(node.body);
		var fnName = name;
		var overloadingNodes = null;
		if (this.overloadings.exists(name)) {
			var overloadings = this.overloadings.get(name);
			if (overloadings.length > 1) {
				var index = overloadings.indexOf(node);
				fnName += '_' + index;
				if (index === overloadings.length - 1) {
					overloadingNodes = overloadings;
				}
			}
		}
		var funcStr = 'const ' + fnName + ' = tslFn( ($' + paramsStr + ') => {\n\n' + this.tab + bodyStr + '\n\n' + this.tab + '} );\n';
		var layoutInput = inputs.length > 0 ? '\n\t\t' + this.tab + inputs.join('\n\t\t' + this.tab) + '\n\t' + this.tab : '';
		if (node.layout !== false && hasPointer === false) {
			var uniqueName = this.uniqueNames ? fnName + '_' + Math.random().toString(36).slice(2) : fnName;
			this.layoutsCode += this.tab + fnName + '.setLayout( {\n' + this.tab + '\tname: \'' + uniqueName + '\',\n' + this.tab + '\ttype: \'' + type + '\',\n' + this.tab + '\tinputs: [ ' + layoutInput + ' ]\n' + this.tab + '} );\n\n';
		}
		this.imports.add('tslFn');
		this.global.add(node.name);
		if (overloadingNodes !== null) {
			funcStr += '\n' + this.emitOverloadingFunction(overloadingNodes);
		}
		return funcStr;
	}

	public function setLastStatement(statement:Dynamic) {
		this._lastStatement = statement;
	}

	public function emitExtraLine(statement:Dynamic):String {
		var last = this._lastStatement;
		if (last === null) return '';
		if (statement.isReturn) return '\n';
		var isExpression = (st) => st.isFunctionDeclaration !== true && st.isFor !== true && st.isConditional !== true;
		var lastExp = isExpression(last);
		var currExp = isExpression(statement);
		if (lastExp !== currExp || (!lastExp && !currExp)) return '\n';
		return '';
	}

	public function emit(ast:Dynamic):String {
		var code = '\n';
		if (this.iife) this.tab += '\t';
		var overloadings = this.overloadings;
		for (statement in ast.body) {
			if (statement.isFunctionDeclaration) {
				if (overloadings.exists(statement.name) === false) {
					overloadings.set(statement.name, []);
				}
				overloadings.get(statement.name).push(statement);
			}
		}
		for (statement in ast.body) {
			code += this.emitExtraLine(statement);
			if (statement.isFunctionDeclaration) {
				code += this.tab + this.emitFunction(statement);
			} else {
				code += this.tab + this.emitExpression(statement) + ';\n';
			}
			this.setLastStatement(statement);
		}
		var imports = this.imports.toArray();
		var exports = this.global.toArray();
		var layouts = this.layoutsCode.length > 0 ? '\n' + this.tab + '// layouts\n\n' + this.layoutsCode : '';
		var header = '// Three.js Transpiler r' + three.REVISION + '\n\n';
		var footer = '';
		if (this.iife) {
			header += '( function ( TSL, uniforms ) {\n\n';
			header += imports.length > 0 ? '\tconst { ' + imports.join(', ') + ' } = TSL;\n' : '';
			footer += exports.length > 0 ? '\treturn { ' + exports.join(', ') + ' };\n' : '';
			footer += '\n} );';
		} else {
			header += imports.length > 0 ? 'import { ' + imports.join(', ') + ' } from \'three/nodes\';\n' : '';
			footer += exports.length > 0 ? 'export { ' + exports.join(', ') + ' };\n' : '';
		}
		return header + code + layouts + footer;
	}

}