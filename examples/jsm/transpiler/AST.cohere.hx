class Program {
    var body:Array<Dynamic>;
    var isProgram:Bool;
    function new() {
        body = [];
        isProgram = true;
    }
}

class VariableDeclaration {
    var type:Dynamic;
    var name:String;
    var value:Dynamic;
    var next:Dynamic;
    var immutable:Bool;
    var isVariableDeclaration:Bool;
    function new(type:Dynamic, name:String, value:Dynamic = null, next:Dynamic = null, immutable:Bool = false) {
        this.type = type;
        this.name = name;
        this.value = value;
        this.next = next;
        this.immutable = immutable;
        isVariableDeclaration = true;
    }
}

class Uniform {
    var type:Dynamic;
    var name:String;
    var isUniform:Bool;
    function new(type:Dynamic, name:String) {
        this.type = type;
        this.name = name;
        isUniform = true;
    }
}

class Varying {
    var type:Dynamic;
    var name:String;
    var isVarying:Bool;
    function new(type:Dynamic, name:String) {
        this.type = type;
        this.name = name;
        isVarying = true;
    }
}

class FunctionParameter {
    var type:Dynamic;
    var name:String;
    var qualifier:Dynamic;
    var immutable:Bool;
    var isFunctionParameter:Bool;
    function new(type:Dynamic, name:String, qualifier:Dynamic = null, immutable:Bool = true) {
        this.type = type;
        this.name = name;
        this.qualifier = qualifier;
        this.immutable = immutable;
        isFunctionParameter = true;
    }
}

class FunctionDeclaration {
    var type:Dynamic;
    var name:String;
    var params:Array<Dynamic>;
    var body:Array<Dynamic>;
    var isFunctionDeclaration:Bool;
    function new(type:Dynamic, name:String, params:Array<Dynamic> = []) {
        this.type = type;
        this.name = name;
        this.params = params;
        body = [];
        isFunctionDeclaration = true;
    }
}

class Expression {
    var expression:Dynamic;
    var isExpression:Bool;
    function new(expression:Dynamic) {
        this.expression = expression;
        isExpression = true;
    }
}

class Ternary {
    var cond:Dynamic;
    var left:Dynamic;
    var right:Dynamic;
    var isTernary:Bool;
    function new(cond:Dynamic, left:Dynamic, right:Dynamic) {
        this.cond = cond;
        this.left = left;
        this.right = right;
        isTernary = true;
    }
}

class Operator {
    var type:Dynamic;
    var left:Dynamic;
    var right:Dynamic;
    var isOperator:Bool;
    function new(type:Dynamic, left:Dynamic, right:Dynamic) {
        this.type = type;
        this.left = left;
        this.right = right;
        isOperator = true;
    }
}

class Unary {
    var type:Dynamic;
    var expression:Dynamic;
    var after:Bool;
    var isUnary:Bool;
    function new(type:Dynamic, expression:Dynamic, after:Bool = false) {
        this.type = type;
        this.expression = expression;
        this.after = after;
        isUnary = true;
    }
}

class Number {
    var type:String;
    var value:Dynamic;
    var isNumber:Bool;
    function new(value:Dynamic, type:String = 'float') {
        this.type = type;
        this.value = value;
        isNumber = true;
    }
}

class String {
    var value:String;
    var isString:Bool;
    function new(value:String) {
        this.value = value;
        isString = true;
    }
}

class Conditional {
    var cond:Dynamic;
    var body:Array<Dynamic>;
    var elseConditional:Dynamic;
    var isConditional:Bool;
    function new(cond:Dynamic = null) {
        this.cond = cond;
        body = [];
        this.elseConditional = null;
        isConditional = true;
    }
}

class FunctionCall {
    var name:String;
    var params:Array<Dynamic>;
    var isFunctionCall:Bool;
    function new(name:String, params:Array<Dynamic> = []) {
        this.name = name;
        this.params = params;
        isFunctionCall = true;
    }
}

class Return {
    var value:Dynamic;
    var isReturn:Bool;
    function new(value:Dynamic) {
        this.value = value;
        isReturn = true;
    }
}

class Accessor {
    var property:Dynamic;
    var isAccessor:Bool;
    function new(property:Dynamic) {
        this.property = property;
        isAccessor = true;
    }
}

class StaticElement {
    var value:Dynamic;
    var isStaticElement:Bool;
    function new(value:Dynamic) {
        this.value = value;
        isStaticElement = true;
    }
}

class DynamicElement {
    var value:Dynamic;
    var isDynamicElement:Bool;
    function new(value:Dynamic) {
        this.value = value;
        isDynamicElement = true;
    }
}

class AccessorElements {
    var property:Dynamic;
    var elements:Array<Dynamic>;
    var isAccessorElements:Bool;
    function new(property:Dynamic, elements:Array<Dynamic> = []) {
        this.property = property;
        this.elements = elements;
        isAccessorElements = true;
    }
}

class For {
    var initialization:Dynamic;
    var condition:Dynamic;
    var afterthought:Dynamic;
    var body:Array<Dynamic>;
    var isFor:Bool;
    function new(initialization:Dynamic, condition:Dynamic, afterthought:Dynamic) {
        this.initialization = initialization;
        this.condition = condition;
        this.afterthought = afterthought;
        body = [];
        isFor = true;
    }
}