import three.nodes.Nodes;

class TSLEncoder {

	private var tab:String;
	private var imports:Set<String>;
	private var global:Set<String>;
	private var overloadings:Map<String, Array<Dynamic>>;
	private var layoutsCode:String;
	private var iife:Bool;
	private var uniqueNames:Bool;
	private var reference:Bool;

	private var _currentProperties:Dict<Dynamic>;
	private var _lastStatement:Dynamic;

	public function new() {
		this.tab = '';
		this.imports = new Set<String>();
		this.global = new Set<String>();
		this.overloadings = new Map<String, Array<Dynamic>>();
		this.layoutsCode = '';
		this.iife = false;
		this.uniqueNames = false;
		this.reference = false;

		this._currentProperties = new Dict<Dynamic>();
		this._lastStatement = null;
	}

	public function addImport(name:String) {
		if (Nodes[name] !== undefined && this.global.has(name) === false && this._currentProperties[name] === undefined) {
			this.imports.add(name);
		}
	}

	public function emitUniform(node:Dynamic) {
		let code = 'const ' + node.name + ' = ';

		if (this.reference === true) {
			this.addImport('reference');

			this.global.add(node.name);

			//code += `reference( '${ node.name }', '${ node.type }', uniforms )`;

			// legacy
			code += `reference( 'value', '${ node.type }', uniforms[ '${ node.name }' ] )`;

		} else {
			this.addImport('uniform');

			this.global.add(node.name);

			code += `uniform( '${ node.type }' )`;
		}

		return code;
	}

	public function emitExpression(node:Dynamic):String {
		let code:String;

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

			code = '"' + node.value + '"';

		} else if (node.isOperator) {

			const opFn = opLib[node.type] || node.type;

			const left = this.emitExpression(node.left);
			const right = this.emitExpression(node.right);

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

			const params = [];

			for (param in node.params) {
				params.push(this.emitExpression(param));
			}

			this.addImport(node.name);

			const paramsStr = params.length > 0 ? ' ' + params.join(', ') + ' ' : '';

			code = `${node.name}(${paramsStr})`;

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

					const value = this.emitExpression(element.value);

					if (isPrimitive(value)) {

						code += `[ ${value} ]`;

					} else {

						code += `.element( ${value} )`;

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

			let type = unaryLib[node.type];

			if (node.after === false && (node.type === '++' || node.type === '--')) {

				type += 'Before';

			}

			const exp = this.emitExpression(node.expression);

			if (isPrimitive(exp)) {

				this.addImport(type);

				code = type + '( ' + exp + ' )';

			} else {

				code = exp + '.' + type + '()';

			}

		} else {

			console.warn('Unknown node type', node);
		}

		if (!code) code = '/* unknown statement */';

		return code;
	}

	// ... other functions omitted for brevity

}