import three.REVISION;
import three.nodes.Nodes.*;
import three.AST.*;

class TSLEncoder {

    static var opLib = {
        '=': 'assign',
        '+': 'add',
        '-': 'sub',
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

    static function isPrimitive(value:String):Bool {
        return /^(true|false|-?\d)/.test(value);
    }

    var tab:String;
    var imports:Set<String>;
    var global:Set<String>;
    var overloadings:Map<String, Array<Dynamic>>;
    var layoutsCode:String;
    var iife:Bool;
    var uniqueNames:Bool;
    var reference:Bool;
    var _currentProperties:Dynamic;
    var _lastStatement:Dynamic;

    public function new() {
        this.tab = '';
        this.imports = new Set();
        this.global = new Set();
        this.overloadings = new Map();
        this.layoutsCode = '';
        this.iife = false;
        this.uniqueNames = false;
        this.reference = false;
        this._currentProperties = {};
        this._lastStatement = null;
    }

    function addImport(name:String):Void {
        name = name.split('.')[0];
        if (Nodes[name] !== undefined && this.global.has(name) === false && this._currentProperties[name] === undefined) {
            this.imports.add(name);
        }
    }

    function emitUniform(node:Dynamic):String {
        var code = 'const ' + node.name + ' = ';
        if (this.reference === true) {
            this.addImport('reference');
            this.global.add(node.name);
            code += 'reference(\'value\', \'' + node.type + '\', uniforms[ \'' + node.name + '\' ])';
        } else {
            this.addImport('uniform');
            this.global.add(node.name);
            code += 'uniform(\'' + node.type + '\')';
        }
        return code;
    }

    function emitExpression(node:Dynamic):String {
        var code:String;
        if (node.isAccessor) {
            this.addImport(node.property);
            code = node.property;
        } else if (node.isNumber) {
            if (node.type === 'int' || node.type === 'uint') {
                code = node.type + '(' + node.value + ')';
                this.addImport(node.type);
            } else {
                code = node.value;
            }
        } else if (node.isString) {
            code = '\'' + node.value + '\'';
        } else if (node.isOperator) {
            var opFn = opLib[node.type] || node.type;
            var left = this.emitExpression(node.left);
            var right = this.emitExpression(node.right);
            if (isPrimitive(left) && isPrimitive(right)) {
                return left + ' ' + node.type + ' ' + right;
            }
            if (isPrimitive(left)) {
                code = opFn + '(' + left + ', ' + right + ')';
                this.addImport(opFn);
            } else {
                code = left + '.' + opFn + '(' + right + ')';
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
                        code += '.element(' + value + ')';
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
            var type = unaryLib[node.type];
            if (node.after === false && (node.type === '++' || node.type === '--')) {
                type += 'Before';
            }
            var exp = this.emitExpression(node.expression);
            if (isPrimitive(exp)) {
                code = type + '(' + exp + ')';
                this.addImport(type);
            } else {
                code = exp + '.' + type + '()';
            }
        } else {
            trace('Unknown node type', node);
        }
        if (!code) code = '/* unknown statement */';
        return code;
    }

    function emitBody(body:Array<Dynamic>):String {
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

    function emitTernary(node:Dynamic):String {
        var condStr = this.emitExpression(node.cond);
        var leftStr = this.emitExpression(node.left);
        var rightStr = this.emitExpression(node.right);
        this.addImport('cond');
        return 'cond(' + condStr + ', ' + leftStr + ', ' + rightStr + ')';
    }

    function emitConditional(node:Dynamic):String {
        var condStr = this.emitExpression(node.cond);
        var bodyStr = this.emitBody(node.body);
        var ifStr = 'If(' + condStr + ', () => {\n\n' + bodyStr + '\n\n' + this.tab + '})';
        var current = node;
        while (current.elseConditional) {
            var elseBodyStr = this.emitBody(current.elseConditional.body);
            if (current.elseConditional.cond) {
                var elseCondStr = this.emitExpression(current.elseConditional.cond);
                ifStr += '.elseif(' + elseCondStr + ', () => {\n\n' + elseBodyStr + '\n\n' + this.tab + '})';
            } else {
                ifStr += '.else(() => {\n\n' + elseBodyStr + '\n\n' + this.tab + '})';
            }
            current = current.elseConditional;
        }
        this.imports.add('If');
        return ifStr;
    }

    function emitLoop(node:Dynamic):String {
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
        var loopStr = 'loop({ start: ' + start + ', end: ' + end + nameParam + typeParam + conditionParam + updateParam + ' }, ({ ' + name + ' }) => {\n\n';
        loopStr += this.emitBody(node.body) + '\n\n' + this.tab + '})';
        this.imports.add('loop');
        return loopStr;
    }

    function emitFor(node:Dynamic):String {
        var initialization = this.emitExpression(node.initialization);
        var condition = this.emitExpression(node.condition);
        var afterthought = this.emitExpression(node.afterthought);
        this.tab += '\t';
        var forStr = '{\n\n' + this.tab + initialization + ';\n\n';
        forStr += 'While(' + condition + ', () => {\n\n';
        forStr += this.emitBody(node.body) + '\n\n';
        forStr += this.tab + '\t' + afterthought + ';\n\n';
        forStr += this.tab + '})\n\n';
        this.tab = this.tab.slice(0, -1);
        forStr += this.tab + '}';
        this.imports.add('While');
        return forStr;
    }

    function emitForWhile(node:Dynamic):String {
        var initialization = this.emitExpression(node.initialization);
        var condition = this.emitExpression(node.condition);
        var afterthought = this.emitExpression(node.afterthought);
        this.tab += '\t';
        var forStr = '{\n\n' + this.tab + initialization + ';\n\n';
        forStr += 'While(' + condition + ', () => {\n\n';
        forStr += this.emitBody(node.body) + '\n\n';
        forStr += this.tab + '\t' + afterthought + ';\n\n';
        forStr += this.tab + '})\n\n';
        this.tab = this.tab.slice(0, -1);
        forStr += this.tab + '}';
        this.imports.add('While');
        return forStr;
    }

    function emitVariables(node:Dynamic, isRoot:Bool = true):String {
        var name = node.name;
        var type = node.type;
        var value = node.value;
        var next = node.next;
        var valueStr = value ? this.emitExpression(value) : '';
        var varStr = isRoot ? 'const ' : '';
        varStr += name;
        if (value) {
            if (value.isFunctionCall && value.name === type) {
                varStr += ' = ' + valueStr;
            } else {
                varStr += ' = ' + type + '(' + valueStr + ')';
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

    function setLastStatement(statement:Dynamic):Void {
        this._lastStatement = statement;
    }

    function emitExtraLine(statement:Dynamic):String {
        var last = this._lastStatement;
        if (last === null) return '';
        if (statement.isReturn) return '\n';
        var isExpression = (st) -> st.isFunctionDeclaration !== true && st.isFor !== true && st.isConditional !== true;
        var lastExp = isExpression(last);
        var currExp = isExpression(statement);
        if (lastExp !== currExp || (!lastExp && !currExp)) return '\n';
        return '';
    }

    function emit(ast:Dynamic):String {
        var code = '\n';
        if (this.iife) this.tab += '\t';
        var overloadings = this.overloadings;
        for (statement in ast.body) {
            if (statement.isFunctionDeclaration) {
                if (overloadings.has(statement.name) === false) {
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
        var imports = [...this.imports];
        var exports = [...this.global];
        var layouts = this.layoutsCode.length > 0 ? '\n' + this.tab + '// layouts\n\n' + this.layoutsCode : '';
        var header = '// Three.js Transpiler r' + REVISION + '\n\n';
        var footer = '';
        if (this.iife) {
            header += '(function (TSL, uniforms) {\n\n';
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