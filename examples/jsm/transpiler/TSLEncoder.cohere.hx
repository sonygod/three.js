import js.Node;
import js.Node._Accessor;
import js.Node._Conditional;
import js.Node._DynamicElement;
import js.Node._Expression;
import js.Node._For;
import js.Node._FunctionCall;
import js.Node._FunctionDeclaration;
import js.Node._Number;
import js.Node._Return;
import js.Node._StaticElement;
import js.Node._String;
import js.Node._Ternary;
import js.Node._Unary;
import js.Node._Uniform;
import js.Node._VariableDeclaration;

class TSLEncoder {
	var tab = '';
	var imports = new Set();
	var global = new Set();
	var overloadings = new Map();
	var layoutsCode = '';
	var iife = false;
	var uniqueNames = false;
	var reference = false;
	var _currentProperties = new Map();
	var _lastStatement: js.Node = null;

	public function new() {
		_currentProperties = new Map();
		_lastStatement = null;
	}

	public function addImport(name: String) {
		// import only if it's a node
		name = name.split('.')[0];
		if (Reflect.field(js.Node, name) != null && !global.has(name) && !Map.exists(_currentProperties, name)) {
			imports.add(name);
		}
	}

	public function emitUniform(node: js.Uniform) {
		var code = 'const ${node.name} = ';
		if (reference) {
			addImport('reference');
			global.add(node.name);
			//code += `reference( '${node.name}', '${node.type}', uniforms)`;
			// legacy
			code += `reference('value', '${node.type}', uniforms['${node.name}'])`;
		} else {
			addImport('uniform');
			global.add(node.name);
			code += `uniform('${node.type}')`;
		}
		return code;
	}

	public function emitExpression(node: js.Expression) {
		var code: String;
		/*@TODO: if (node.isVarying) {
			code = emitVarying(node);
		}*/
		if (node.isAccessor) {
			addImport(node.property);
			code = node.property;
		} else if (node.isNumber) {
			if (['int', 'uint'].contains(node.type)) {
				code = '${node.type}(${node.value})';
				addImport(node.type);
			} else {
				code = '${node.value}';
			}
		} else if (node.isString) {
			code = "'${node.value}'";
		} else if (node.isOperator) {
			var opFn = opLib[node.type] ?? node.type;
			var left = emitExpression(node.left);
			var right = emitExpression(node.right);
			if (isPrimitive(left) && isPrimitive(right)) {
				return '${left} ${node.type} ${right}';
			}
			if (isPrimitive(left)) {
				code = '${opFn}(${left}, ${right})';
				addImport(opFn);
			} else {
				code = '${left}.${opFn}(${right})';
			}
		} else if (node.isFunctionCall) {
			var params = [];
			for (param in node.params) {
				params.push(emitExpression(param));
			}
			addImport(node.name);
			var paramsStr = params.length > 0 ? ' ${params.join(', ')}' : '';
			code = '${node.name}(${paramsStr})';
		} else if (node.isReturn) {
			code = 'return';
			if (node.value != null) {
				code += ' ' + emitExpression(node.value);
			}
		} else if (node.isAccessorElements) {
			code = node.property;
			for (element in node.elements) {
				if (element.isStaticElement) {
					code += '.${emitExpression(element.value)}';
				} else if (element.isDynamicElement) {
					var value = emitExpression(element.value);
					if (isPrimitive(value)) {
						code += `[${value}]`;
					} else {
						code += '.element(${value})';
					}
				}
			}
		} else if (node.isDynamicElement) {
			code = emitExpression(node.value);
		} else if (node.isStaticElement) {
			code = emitExpression(node.value);
		} else if (node.isFor) {
			code = emitFor(node);
		} else if (node.isVariableDeclaration) {
			code = emitVariables(node);
		} else if (node.isUniform) {
			code = emitUniform(node);
		} else if (node.isTernary) {
			code = emitTernary(node);
		} else if (node.isConditional) {
			code = emitConditional(node);
		} else if (node.isUnary && node.expression.isNumber) {
			code = '${node.type} ${node.expression.value}';
		} else if (node.isUnary) {
			var type = unaryLib[node.type];
			if (node.after == false && ['++', '--'].contains(node.type)) {
				type += 'Before';
			}
			var exp = emitExpression(node.expression);
			if (isPrimitive(exp)) {
				addImport(type);
				code = '${type}(${exp})';
			} else {
				code = '${exp}.${type}()';
			}
		} else {
			throw 'Unknown node type: ${node}';
		}
		if (code == null) code = '/* unknown statement */';
		return code;
	}

	public function emitBody(body: Array<js.Node>) {
		_lastStatement = null;
		var code = '';
		tab += '\t';
		for (statement in body) {
			code += emitExtraLine(statement);
			code += tab + emitExpression(statement);
			if (code.endsWith('}')) code += ';';
			code += '\n';
			_lastStatement = statement;
		}
		code = code.substring(0, code.length - 1); // remove the last extra line
		tab = tab.substring(0, tab.length - 1);
		return code;
	}

	public function emitTernary(node: js.Ternary) {
		var condStr = emitExpression(node.cond);
		var leftStr = emitExpression(node.left);
		var rightStr = emitExpression(node.right);
		addImport('cond');
		return 'cond(${condStr}, ${leftStr}, ${rightStr})';
	}

	public function emitConditional(node: js.Conditional) {
		var condStr = emitExpression(node.cond);
		var bodyStr = emitBody(node.body);
		var ifStr = `If(${condStr}, () => {

${bodyStr}

${tab}})`;
		var current = node;
		while (current.elseConditional != null) {
			var elseBodyStr = emitBody(current.elseConditional.body);
			if (current.elseConditional.cond != null) {
				var elseCondStr = emitExpression(current.elseConditional.cond);
				ifStr += `.elseif(${elseCondStr}, () => {

${elseBodyStr}

${tab}})`;
			} else {
				ifStr += `.else(() => {

${elseBodyStr}

${tab}})`;
			}
			current = current.elseConditional;
		}
		imports.add('If');
		return ifStr;
	}

	public function emitLoop(node: js.For) {
		var start = emitExpression(node.initialization.value);
		var end = emitExpression(node.condition.right);
		var name = node.initialization.name;
		var type = node.initialization.type;
		var condition = node.condition.type;
		var update = node.afterthought.type;
		var nameParam = name != 'i' ? `, name: '${name}'` : '';
		var typeParam = type != 'int' ? `, type: '${type}'` : '';
		var conditionParam = condition != '<' ? `, condition: '${condition}'` : '';
		var updateParam = update != '++' ? `, update: '${update}'` : '';
		var loopStr = `loop({ start: ${start}, end: ${end}${nameParam}${typeParam}${conditionParam}${updateParam}}, ({ ${name} }) => {

${emitBody(node.body)}

${tab}})`;
		imports.add('loop');
		return loopStr;
	}

	public function emitFor(node: js.For) {
		var initialization = emitExpression(node.initialization);
		var condition = emitExpression(node.condition);
		var afterthought = emitExpression(node.afterthought);
		tab += '\t';
		var forStr = '{\n\n' + tab + initialization + ';\n\n';
		forStr += `${tab}While(${condition}, () => {\n\n`;
		forStr += emitBody(node.body) + '\n\n';
		forStr += tab + '\t' + afterthought + ';\n\n';
		forStr += tab + '})\n\n';
		tab = tab.substring(0, tab.length - 1);
		forStr += tab + '}';
		imports.add('While');
		return forStr;
	}

	public function emitVariables(node: js.VariableDeclaration, isRoot = true) {
		var name = node.name;
		var type = node.type;
		var value = node.value;
		var next = node.next;
		var valueStr = value != null ? emitExpression(value) : '';
		var varStr = isRoot ? 'const ' : '';
		varStr += name;
		if (value != null) {
			if (value.isFunctionCall && value.name == type) {
				varStr += ' = ' + valueStr;
			} else {
				varStr += ` = ${type}(${valueStr})`;
			}
		} else {
			varStr += ` = ${type}()`;
		}
		if (node.immutable == false) {
			varStr += '.toVar()';
		}
		if (next != null) {
			varStr += ', ' + emitVariables(next, false);
		}
		addImport(type);
		return varStr;
	}

	/*public function emitVarying(node: js.Node) { }*/

	public function emitOverloadingFunction(nodes: Array<js.FunctionDeclaration>) {
		var name = nodes[0].name;
		addImport('overloadingFn');
		return `const ${name} = overloadingFn([ ${nodes.map((node, i) => node.name + '_' + i).join(', ')} ]);\n`;
	}

	public function emitFunction(node: js.FunctionDeclaration) {
		var name = node.name;
		var type = node.type;
		_currentProperties = new Map();
		_currentProperties['name'] = node;
		var params = [];
		var inputs = [];
		var mutableParams = [];
		var hasPointer = false;
		for (param in node.params) {
			var str = `{ name: '${param.name}', type: '${param.type}'`;
			var name = param.name;
			if (param.immutable == false && ['inout', 'out'].contains(param.qualifier) == false) {
				name = name + '_immutable';
				mutableParams.push(param);
			}
			if (param.qualifier != null) {
				if (['inout', 'out'].contains(param.qualifier)) {
					hasPointer = true;
				}
				str += `, qualifier: '${param.qualifier}'`;
			}
			inputs.push(str + '}');
			params.push(name);
			_currentProperties[name] = param;
		}
		for (param in mutableParams) {
			node.body.unshift(new js.VariableDeclaration(param.type, param.name, new js.Accessor(param.name + '_immutable')));
		}
		var paramsStr = params.length > 0 ? ' [ ' + params.join(', ') + ' ] ' : '';
		var bodyStr = emitBody(node.body);
		var fnName = name;
		var overloadingNodes = null;
		if (overloadings.has(name)) {
			var overloadings = overloadings.get(name);
			if (overloadings.length > 1) {
				var index = overloadings.indexOf(node);
				fnName += '_' + index;
				if (index == overloadings.length - 1) {
					overloadingNodes = overloadings;
				}
			}
		}
		var funcStr = `const ${fnName} = tslFn((${paramsStr}) => {

${bodyStr}

${tab}});\n`;
		var layoutInput = inputs.length > 0 ? '\n\t\t' + tab + inputs.join(',\n\t\t' + tab) + '\n\t' + tab : '';
		if (node.layout != false && hasPointer == false) {
			var uniqueName = uniqueNames ? fnName + '_' + Std.random(16).toString(16).toUpperCase() : fnName;
			layoutsCode += `${tab + fnName}.setLayout({
${tab}\tname: '${uniqueName}',
${tab}\ttype: '${type}',
${tab}\tinputs: [${layoutInput}]
${tab}});\n\n`;
		}
		imports.add('tslFn');
		global.add(node.name);
		if (overloadingNodes != null) {
			funcStr += '\n' + emitOverloadingFunction(overloadingNodes);
		}
		return funcStr;
	}

	public function setLastStatement(statement: js.Node) {
		_lastStatement = statement;
	}

	public function emitExtraLine(statement: js.Node) {
		var last = _lastStatement;
		if (last == null) return '';
		if (statement.isReturn) return '\n';
		function isExpression(st: js.Node) {
			return st.isFunctionDeclaration == false && st.isFor == false && st.isConditional == false;
		}
		var lastExp = isExpression(last);
		var currExp = isExpression(statement);
		if (lastExp != currExp || (!lastExp && !currExp)) return '\n';
		return '';
	}

	public function emit(ast: js.Node) {
		var code = '\n';
		if (iife) tab += '\t';
		var overloadings = overloadings;
		for (statement in ast.body) {
			if (statement.isFunctionDeclaration) {
				if (!overloadings.has(statement.name)) {
					overloadings.set(statement.name, []);
				}
				overloadings.get(statement.name).push(statement);
			}
		}
		for (statement in ast.body) {
			code += emitExtraLine(statement);
			if (statement.isFunctionDeclaration) {
				code += tab + emitFunction(statement);
			} else {
				code += tab + emitExpression(statement) + ';\n';
			}
			_lastStatement = statement;
		}
		var imports = Array.from(imports);
		var exports = Array.from(global);
		var layouts = layoutsCode.length > 0 ? `\n${tab}// layouts\n\n${layoutsCode}` : '';
		var header = '// Three.js Transpiler r' + REVISION + '\n\n';
		var footer = '';
		if (iife) {
			header += '(function (TSL, uniforms) {\n\n';
			header += imports.length > 0 ? '\tconst { ' + imports.join(', ') + ' } = TSL;\n' : '';
			footer += exports.length > 0 ? '\treturn { ' + exports.join(', ') + ' };\n' : '';
			footer += '\n});';
		} else {
			header += imports.length > 0 ? 'import { ' + imports.join(', ') + ' } from \'three/nodes\';\n' : '';
			footer += exports.length > 0 ? 'export { ' + exports.join(', ') + ' };\n' : '';
		}
		return header + code + layouts + footer;
	}

	static var opLib = {
		'=': 'assign',
		'+': 'add',
		'-
		'*': 'mul',
		'/': 'div',
		'%': 'remainder',
		'<': 'lessThan',
		'>': 'greaterThan',
		'<=': 'lessThanEqual',
		'>=': 'greaterThanEqual',
		'==': 'equal',
		'&&': 'and',
		'||': 'or',
		'^^': 'xor',
		'&': 'bitAnd',
		'|': 'bitOr',
		'^': 'bitXor',
		'<<': 'shiftLeft',
		'>>': 'shiftRight',
		'+=': 'addAssign',
		'-=': 'subAssign',
		'*=': 'mulAssign',
		'/=': 'divAssign',
		'%=': 'remainderAssign',
		'^=': 'bitXorAssign',
		'&=': 'bitAndAssign',
		'|=': 'bitOrAssign',
		'<<=': 'shiftLeftAssign',
		'>>=': 'shiftRightAssign'
	};

	static var unaryLib = {
		'+': '', // positive
		'-': 'negate',
		'~': 'bitNot',
		'!': 'not',
		'++': 'increment', // incrementBefore
		'--': 'decrement' // decrementBefore
	};

	static function isPrimitive(value: String) {
		return /^(true|false|-?\d)/.match(value) != null;
	}
}

class js {
	static class Node {
		public var isAccessor: Bool;
		public var isConditional: Bool;
		public var isDynamicElement: Bool;
		public var isExpression: Bool;
		public var isFor: Bool;
		public var isFunctionCall: Bool;
		public var isFunctionDeclaration: Bool;
		public var isNumber: Bool;
		public var isReturn: Bool;
		public var isStaticElement: Bool;
		public var isString: Bool;
		public var isTernary: Bool;
		public var isUnary: Bool;
		public var isUniform: Bool;
		public var isVariableDeclaration: Bool;
		//public var isVarying: Bool;

		public var property: String;
		public var type: String;
		public var value: String;
		public var name: String;
		public var next: Node;
		public var params: Array<Node>;
		public var body: Array<Node>;
		public var elements: Array<Node>;
		public var initialization: Node;
		public var condition: Node;
		public var afterthought: Node;
		public var expression: Node;
		public var left: Node;
		public var right: Node;
		public var cond: Node;
		public var param: Node;
		public var immutable: Bool;
		public var qualifier: String;
		public var layout: Bool;
		public var elseConditional: Conditional;

		public function new() {
			isAccessor = false;
			isConditional = false;
			isDynamicElement = false;
			isExpression = false;
			isFor = false;
			isFunctionCall = false;
			isFunctionDeclaration = false;
			isNumber = false;
			isReturn = false;
			isStaticElement = false;
			isString = false;
			isTernary = false;
			isUnary = false;
			isUniform = false;
			isVariableDeclaration = false;
			//isVarying = false;

			property = '';
			type = '';
			value = '';
			name = '';
			next = null;
			params = [];
			body = [];
			elements = [];
			initialization = null;
			condition = null;
			afterthought = null;
			expression = null;
			left = null;
			right = null;
			cond = null;
			param = null;
			immutable = false;
			qualifier = '';
			layout = false;
			elseConditional = null;
		}
	}

	static class _Accessor extends Node {
		public function new() {
			super();
			isAccessor = true;
		}
	}

	static class _Conditional extends Node {
		public function new() {
			super();
			isConditional = true;
		}
	}

	static class _DynamicElement extends Node {
		public function new() {
			super();
			isDynamicElement = true;
		}
	}

	static class _Expression extends Node {
		public function new() {
			super();
			isExpression = true;
		}
	}

	static class _For extends Node {
		public function new() {
			super();
			isFor = true;
		}
	}

	static class _FunctionCall extends Node {
		public function new() {
			super();
			isFunctionCall = true;
		}
	}

	static class _FunctionDeclaration extends Node {
		public function new() {
			super();
			isFunctionDeclaration = true;
		}
	}

	static class _Number extends Node {
		public function new() {
			super();
			isNumber = true;
		}
	}

	static class _Return extends Node {
		public function new() {
			super();
			isReturn = true;
		}
	}

	static class _StaticElement extends Node {
		public function new() {
			super();
			isStaticElement = true;
		}
	}

	static class _String extends Node {
		public function new() {
			super();
			isString = true;
		}
	}

	static class _Ternary extends Node {
		public function new() {
			super();
			isTernary = true;
		}
	}

	static class _Unary extends Node {
		public function new() {
			super();
			isUnary = true;
		}
	}

	static class _Uniform extends Node {
		public function new() {
			super();
			isUniform = true;
		}
	}

	static class _VariableDeclaration extends Node {
		public function new() {
			super();
			isVariableDeclaration = true;
		}
	}

	//static class _Varying extends Node {
	//	public function new() {
	//		super();
	//		isVarying = true;
	//	}
}