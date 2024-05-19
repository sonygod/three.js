package three.js.examples.jsm.transpiler;

class Program {
    public var body:Array<Dynamic>;

    public function new() {
        body = [];
        isProgram = true;
    }

    public var isProgram:Bool;
}

class VariableDeclaration {
    public var type:Dynamic;
    public var name:String;
    public var value:Dynamic;
    public var next:Dynamic;
    public var immutable:Bool;

    public function new(type:Dynamic, name:String, value:Dynamic = null, next:Dynamic = null, immutable:Bool = false) {
        this.type = type;
        this.name = name;
        this.value = value;
        this.next = next;
        this.immutable = immutable;
        isVariableDeclaration = true;
    }

    public var isVariableDeclaration:Bool;
}

class Uniform {
    public var type:Dynamic;
    public var name:String;

    public function new(type:Dynamic, name:String) {
        this.type = type;
        this.name = name;
        isUniform = true;
    }

    public var isUniform:Bool;
}

class Varying {
    public var type:Dynamic;
    public var name:String;

    public function new(type:Dynamic, name:String) {
        this.type = type;
        this.name = name;
        isVarying = true;
    }

    public var isVarying:Bool;
}

class FunctionParameter {
    public var type:Dynamic;
    public var name:String;
    public var qualifier:Dynamic;
    public var immutable:Bool;

    public function new(type:Dynamic, name:String, qualifier:Dynamic = null, immutable:Bool = true) {
        this.type = type;
        this.name = name;
        this.qualifier = qualifier;
        this.immutable = immutable;
        isFunctionParameter = true;
    }

    public var isFunctionParameter:Bool;
}

class FunctionDeclaration {
    public var type:Dynamic;
    public var name:String;
    public var params:Array<FunctionParameter>;
    public var body:Array<Dynamic>;

    public function new(type:Dynamic, name:String, params:Array<FunctionParameter> = []) {
        this.type = type;
        this.name = name;
        this.params = params;
        body = [];
        isFunctionDeclaration = true;
    }

    public var isFunctionDeclaration:Bool;
}

class Expression {
    public var expression:Dynamic;

    public function new(expression:Dynamic) {
        this.expression = expression;
        isExpression = true;
    }

    public var isExpression:Bool;
}

class Ternary {
    public var cond:Dynamic;
    public var left:Dynamic;
    public var right:Dynamic;

    public function new(cond:Dynamic, left:Dynamic, right:Dynamic) {
        this.cond = cond;
        this.left = left;
        this.right = right;
        isTernary = true;
    }

    public var isTernary:Bool;
}

class Operator {
    public var type:Dynamic;
    public var left:Dynamic;
    public var right:Dynamic;

    public function new(type:Dynamic, left:Dynamic, right:Dynamic) {
        this.type = type;
        this.left = left;
        this.right = right;
        isOperator = true;
    }

    public var isOperator:Bool;
}

class Unary {
    public var type:Dynamic;
    public var expression:Dynamic;
    public var after:Bool;

    public function new(type:Dynamic, expression:Dynamic, after:Bool = false) {
        this.type = type;
        this.expression = expression;
        this.after = after;
        isUnary = true;
    }

    public var isUnary:Bool;
}

class Number {
    public var type:String;
    public var value:Dynamic;

    public function new(value:Dynamic, type:String = 'float') {
        this.type = type;
        this.value = value;
        isNumber = true;
    }

    public var isNumber:Bool;
}

class String {
    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
        isString = true;
    }

    public var isString:Bool;
}

class Conditional {
    public var cond:Dynamic;
    public var body:Array<Dynamic>;
    public var elseConditional:Dynamic;

    public function new(cond:Dynamic = null) {
        this.cond = cond;
        body = [];
        elseConditional = null;
        isConditional = true;
    }

    public var isConditional:Bool;
}

class FunctionCall {
    public var name:String;
    public var params:Array<Dynamic>;

    public function new(name:String, params:Array<Dynamic> = []) {
        this.name = name;
        this.params = params;
        isFunctionCall = true;
    }

    public var isFunctionCall:Bool;
}

class Return {
    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
        isReturn = true;
    }

    public var isReturn:Bool;
}

class Accessor {
    public var property:Dynamic;

    public function new(property:Dynamic) {
        this.property = property;
        isAccessor = true;
    }

    public var isAccessor:Bool;
}

class StaticElement {
    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
        isStaticElement = true;
    }

    public var isStaticElement:Bool;
}

class DynamicElement {
    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
        isDynamicElement = true;
    }

    public var isDynamicElement:Bool;
}

class AccessorElements {
    public var property:Dynamic;
    public var elements:Array<Dynamic>;

    public function new(property:Dynamic, elements:Array<Dynamic> = []) {
        this.property = property;
        this.elements = elements;
        isAccessorElements = true;
    }

    public var isAccessorElements:Bool;
}

class For {
    public var initialization:Dynamic;
    public var condition:Dynamic;
    public var afterthought:Dynamic;
    public var body:Array<Dynamic>;

    public function new(initialization:Dynamic, condition:Dynamic, afterthought:Dynamic) {
        this.initialization = initialization;
        this.condition = condition;
        this.afterthought = afterthought;
        body = [];
        isFor = true;
    }

    public var isFor:Bool;
}