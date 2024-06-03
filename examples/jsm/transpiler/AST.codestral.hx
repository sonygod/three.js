class Program {
    public var body:Array<Dynamic> = [];
    public var isProgram:Bool = true;
}

class VariableDeclaration {
    public var type:String;
    public var name:String;
    public var value:Dynamic;
    public var next:VariableDeclaration;
    public var immutable:Bool;
    public var isVariableDeclaration:Bool = true;

    public function new(type:String, name:String, value:Dynamic = null, next:VariableDeclaration = null, immutable:Bool = false) {
        this.type = type;
        this.name = name;
        this.value = value;
        this.next = next;
        this.immutable = immutable;
    }
}

class Uniform {
    public var type:String;
    public var name:String;
    public var isUniform:Bool = true;

    public function new(type:String, name:String) {
        this.type = type;
        this.name = name;
    }
}

class Varying {
    public var type:String;
    public var name:String;
    public var isVarying:Bool = true;

    public function new(type:String, name:String) {
        this.type = type;
        this.name = name;
    }
}

class FunctionParameter {
    public var type:String;
    public var name:String;
    public var qualifier:String;
    public var immutable:Bool;
    public var isFunctionParameter:Bool = true;

    public function new(type:String, name:String, qualifier:String = null, immutable:Bool = true) {
        this.type = type;
        this.name = name;
        this.qualifier = qualifier;
        this.immutable = immutable;
    }
}

class FunctionDeclaration {
    public var type:String;
    public var name:String;
    public var params:Array<FunctionParameter> = [];
    public var body:Array<Dynamic> = [];
    public var isFunctionDeclaration:Bool = true;

    public function new(type:String, name:String, params:Array<FunctionParameter> = []) {
        this.type = type;
        this.name = name;
        this.params = params;
    }
}

class Expression {
    public var expression:Dynamic;
    public var isExpression:Bool = true;

    public function new(expression:Dynamic) {
        this.expression = expression;
    }
}

class Ternary {
    public var cond:Dynamic;
    public var left:Dynamic;
    public var right:Dynamic;
    public var isTernary:Bool = true;

    public function new(cond:Dynamic, left:Dynamic, right:Dynamic) {
        this.cond = cond;
        this.left = left;
        this.right = right;
    }
}

class Operator {
    public var type:String;
    public var left:Dynamic;
    public var right:Dynamic;
    public var isOperator:Bool = true;

    public function new(type:String, left:Dynamic, right:Dynamic) {
        this.type = type;
        this.left = left;
        this.right = right;
    }
}

class Unary {
    public var type:String;
    public var expression:Dynamic;
    public var after:Bool;
    public var isUnary:Bool = true;

    public function new(type:String, expression:Dynamic, after:Bool = false) {
        this.type = type;
        this.expression = expression;
        this.after = after;
    }
}

class Number {
    public var type:String;
    public var value:Float;
    public var isNumber:Bool = true;

    public function new(value:Float, type:String = 'float') {
        this.type = type;
        this.value = value;
    }
}

class String {
    public var value:String;
    public var isString:Bool = true;

    public function new(value:String) {
        this.value = value;
    }
}

class Conditional {
    public var cond:Dynamic;
    public var body:Array<Dynamic> = [];
    public var elseConditional:Conditional;
    public var isConditional:Bool = true;

    public function new(cond:Dynamic = null) {
        this.cond = cond;
    }
}

class FunctionCall {
    public var name:String;
    public var params:Array<Dynamic> = [];
    public var isFunctionCall:Bool = true;

    public function new(name:String, params:Array<Dynamic> = []) {
        this.name = name;
        this.params = params;
    }
}

class Return {
    public var value:Dynamic;
    public var isReturn:Bool = true;

    public function new(value:Dynamic) {
        this.value = value;
    }
}

class Accessor {
    public var property:String;
    public var isAccessor:Bool = true;

    public function new(property:String) {
        this.property = property;
    }
}

class StaticElement {
    public var value:Dynamic;
    public var isStaticElement:Bool = true;

    public function new(value:Dynamic) {
        this.value = value;
    }
}

class DynamicElement {
    public var value:Dynamic;
    public var isDynamicElement:Bool = true;

    public function new(value:Dynamic) {
        this.value = value;
    }
}

class AccessorElements {
    public var property:String;
    public var elements:Array<Dynamic> = [];
    public var isAccessorElements:Bool = true;

    public function new(property:String, elements:Array<Dynamic> = []) {
        this.property = property;
        this.elements = elements;
    }
}

class For {
    public var initialization:Dynamic;
    public var condition:Dynamic;
    public var afterthought:Dynamic;
    public var body:Array<Dynamic> = [];
    public var isFor:Bool = true;

    public function new(initialization:Dynamic, condition:Dynamic, afterthought:Dynamic) {
        this.initialization = initialization;
        this.condition = condition;
        this.afterthought = afterthought;
    }
}