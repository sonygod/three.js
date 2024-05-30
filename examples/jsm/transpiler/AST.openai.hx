package transpiler.ast;

class Program {
    public var body:Array<Dynamic>;

    public function new() {
        body = [];
    }

    public var isProgram:Bool = true;
}

class VariableDeclaration {
    public var type:Dynamic;
    public var name:String;
    public var value:Dynamic;
    public var next:Dynamic;
    public var immutable:Bool;

    public function new(type:Dynamic, name:String, ?value:Dynamic, ?next:Dynamic, immutable:Bool = false) {
        this.type = type;
        this.name = name;
        this.value = value;
        this.next = next;
        this.immutable = immutable;
    }

    public var isVariableDeclaration:Bool = true;
}

class Uniform {
    public var type:Dynamic;
    public var name:String;

    public function new(type:Dynamic, name:String) {
        this.type = type;
        this.name = name;
    }

    public var isUniform:Bool = true;
}

class Varying {
    public var type:Dynamic;
    public var name:String;

    public function new(type:Dynamic, name:String) {
        this.type = type;
        this.name = name;
    }

    public var isVarying:Bool = true;
}

class FunctionParameter {
    public var type:Dynamic;
    public var name:String;
    public var qualifier:Dynamic;
    public var immutable:Bool;

    public function new(type:Dynamic, name:String, ?qualifier:Dynamic, immutable:Bool = true) {
        this.type = type;
        this.name = name;
        this.qualifier = qualifier;
        this.immutable = immutable;
    }

    public var isFunctionParameter:Bool = true;
}

class FunctionDeclaration {
    public var type:Dynamic;
    public var name:String;
    public var params:Array<FunctionParameter>;
    public var body:Array<Dynamic>;

    public function new(type:Dynamic, name:String, ?params:Array<FunctionParameter>) {
        this.type = type;
        this.name = name;
        this.params = params == null ? [] : params;
        this.body = [];
    }

    public var isFunctionDeclaration:Bool = true;
}

class Expression {
    public var expression:Dynamic;

    public function new(expression:Dynamic) {
        this.expression = expression;
    }

    public var isExpression:Bool = true;
}

class Ternary {
    public var cond:Dynamic;
    public var left:Dynamic;
    public var right:Dynamic;

    public function new(cond:Dynamic, left:Dynamic, right:Dynamic) {
        this.cond = cond;
        this.left = left;
        this.right = right;
    }

    public var isTernary:Bool = true;
}

class Operator {
    public var type:Dynamic;
    public var left:Dynamic;
    public var right:Dynamic;

    public function new(type:Dynamic, left:Dynamic, right:Dynamic) {
        this.type = type;
        this.left = left;
        this.right = right;
    }

    public var isOperator:Bool = true;
}

class Unary {
    public var type:Dynamic;
    public var expression:Dynamic;
    public var after:Bool;

    public function new(type:Dynamic, expression:Dynamic, after:Bool = false) {
        this.type = type;
        this.expression = expression;
        this.after = after;
    }

    public var isUnary:Bool = true;
}

class Number {
    public var type:String;
    public var value:Float;

    public function new(value:Float, type:String = 'float') {
        this.type = type;
        this.value = value;
    }

    public var isNumber:Bool = true;
}

class String {
    public var value:String;

    public function new(value:String) {
        this.value = value;
    }

    public var isString:Bool = true;
}

class Conditional {
    public var cond:Dynamic;
    public var body:Array<Dynamic>;
    public var elseConditional:Conditional;

    public function new(?cond:Dynamic) {
        this.cond = cond;
        this.body = [];
        this.elseConditional = null;
    }

    public var isConditional:Bool = true;
}

class FunctionCall {
    public var name:String;
    public var params:Array<Dynamic>;

    public function new(name:String, ?params:Array<Dynamic>) {
        this.name = name;
        this.params = params == null ? [] : params;
    }

    public var isFunctionCall:Bool = true;
}

class Return {
    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
    }

    public var isReturn:Bool = true;
}

class Accessor {
    public var property:String;

    public function new(property:String) {
        this.property = property;
    }

    public var isAccessor:Bool = true;
}

class StaticElement {
    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
    }

    public var isStaticElement:Bool = true;
}

class DynamicElement {
    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
    }

    public var isDynamicElement:Bool = true;
}

class AccessorElements {
    public var property:String;
    public var elements:Array<Dynamic>;

    public function new(property:String, ?elements:Array<Dynamic>) {
        this.property = property;
        this.elements = elements == null ? [] : elements;
    }

    public var isAccessorElements:Bool = true;
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
        this.body = [];
    }

    public var isFor:Bool = true;
}