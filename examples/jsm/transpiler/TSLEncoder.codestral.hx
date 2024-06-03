import three.REVISION;
import AST.VariableDeclaration;
import AST.Accessor;
import Nodes.*;

class OpLib {
    public static var opLib:Map<String, String> = new Map<String, String>([
        ('=', 'assign'),
        ('+', 'add'),
        ('-', 'sub'),
        ('*', 'mul'),
        ('/', 'div'),
        ('%', 'remainder'),
        ('<', 'lessThan'),
        ('>', 'greaterThan'),
        ('<=', 'lessThanEqual'),
        ('>=', 'greaterThanEqual'),
        ('==', 'equal'),
        ('&&', 'and'),
        ('||', 'or'),
        ('^^', 'xor'),
        ('&', 'bitAnd'),
        ('|', 'bitOr'),
        ('^', 'bitXor'),
        ('<<', 'shiftLeft'),
        ('>>', 'shiftRight'),
        ('+=', 'addAssign'),
        ('-=', 'subAssign'),
        ('*=', 'mulAssign'),
        ('/=', 'divAssign'),
        ('%=', 'remainderAssign'),
        ('^=', 'bitXorAssign'),
        ('&=', 'bitAndAssign'),
        ('|=', 'bitOrAssign'),
        ('<<=', 'shiftLeftAssign'),
        ('>>=', 'shiftRightAssign')
    ]);
}

class UnaryLib {
    public static var unaryLib:Map<String, String> = new Map<String, String>([
        ('+', ''), // positive
        ('-', 'negate'),
        ('~', 'bitNot'),
        ('!', 'not'),
        ('++', 'increment'), // incrementBefore
        ('--', 'decrement') // decrementBefore
    ]);
}

class TSLEncoder {
    private var tab:String;
    private var imports:Set<String>;
    private var global:Set<String>;
    private var overloadings:Map<String, Array<Any>>;
    private var layoutsCode:String;
    private var iife:Bool;
    private var uniqueNames:Bool;
    private var reference:Bool;

    private var _currentProperties:Map<String, Any>;
    private var _lastStatement:Any;

    public function new() {
        this.tab = '';
        this.imports = new Set<String>();
        this.global = new Set<String>();
        this.overloadings = new Map<String, Array<Any>>();
        this.layoutsCode = '';
        this.iife = false;
        this.uniqueNames = false;
        this.reference = false;

        this._currentProperties = new Map<String, Any>();
        this._lastStatement = null;
    }

    public function addImport(name:String):Void {
        name = name.split('.')[0];

        if (Type.resolveClass(name) != null && this.global.has(name) == false && this._currentProperties.exists(name) == false) {
            this.imports.add(name);
        }
    }

    // ... continue this pattern for the remaining functions
}