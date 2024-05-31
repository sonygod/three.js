package three.js.examples.jsm.transpiler;

class Program {

	public var body:Array<Dynamic>;
	public var isProgram:Bool;

	public function new() {

		this.body = [];

		this.isProgram = true;

	}

}

class VariableDeclaration {

	public var type:String;
	public var name:String;
	public var value:Null<Dynamic>;
	public var next:Null<Dynamic>;
	public var immutable:Bool;
	public var isVariableDeclaration:Bool;

	public function new(type:String, name:String, value:Null<Dynamic> = null, next:Null<Dynamic> = null, immutable:Bool = false) {

		this.type = type;
		this.name = name;
		this.value = value;
		this.next = next;

		this.immutable = immutable;

		this.isVariableDeclaration = true;

	}

}

class Uniform {

	public var type:String;
	public var name:String;
	public var isUniform:Bool;

	public function new(type:String, name:String) {

		this.type = type;
		this.name = name;

		this.isUniform = true;

	}

}

class Varying {

	public var type:String;
	public var name:String;
	public var isVarying:Bool;

	public function new(type:String, name:String) {

		this.type = type;
		this.name = name;

		this.isVarying = true;

	}

}

class FunctionParameter {

	public var type:String;
	public var name:String;
	public var qualifier:Null<Dynamic>;
	public var immutable:Bool;
	public var isFunctionParameter:Bool;

	public function new(type:String, name:String, qualifier:Null<Dynamic> = null, immutable:Bool = true) {

		this.type = type;
		this.name = name;
		this.qualifier = qualifier;
		this.immutable = immutable;

		this.isFunctionParameter = true;

	}

}

class FunctionDeclaration {

	public var type:String;
	public var name:String;
	public var params:Array<Dynamic>;
	public var body:Array<Dynamic>;
	public var isFunctionDeclaration:Bool;

	public function new(type:String, name:String, params:Array<Dynamic> = []) {

		this.type = type;
		this.name = name;
		this.params = params;
		this.body = [];

		this.isFunctionDeclaration = true;

	}

}

class Expression {

	public var expression:Dynamic;
	public var isExpression:Bool;

	public function new(expression:Dynamic) {

		this.expression = expression;

		this.isExpression = true;

	}

}

class Ternary {

	public var cond:Dynamic;
	public var left:Dynamic;
	public var right:Dynamic;
	public var isTernary:Bool;

	public function new(cond:Dynamic, left:Dynamic, right:Dynamic) {

		this.cond = cond;
		this.left = left;
		this.right = right;

		this.isTernary = true;

	}

}

class Operator {

	public var type:String;
	public var left:Dynamic;
	public var right:Dynamic;
	public var isOperator:Bool;

	public function new(type:String, left:Dynamic, right:Dynamic) {

		this.type = type;
		this.left = left;
		this.right = right;

		this.isOperator = true;

	}

}

class Unary {

	public var type:String;
	public var expression:Dynamic;
	public var after:Bool;
	public var isUnary:Bool;

	public function new(type:String, expression:Dynamic, after:Bool = false) {

		this.type = type;
		this.expression = expression;
		this.after = after;

		this.isUnary = true;

	}

}

class Number {

	public var type:String;
	public var value:Float;
	public var isNumber:Bool;

	public function new(value:Float, type:String = 'float') {

		this.type = type;
		this.value = value;

		this.isNumber = true;

	}

}

class String {

	public var value:String;
	public var isString:Bool;

	public function new(value:String) {

		this.value = value;

		this.isString = true;

	}

}

class Conditional {

	public var cond:Null<Dynamic>;
	public var body:Array<Dynamic>;
	public var elseConditional:Null<Dynamic>;
	public var isConditional:Bool;

	public function new(cond:Null<Dynamic> = null) {

		this.cond = cond;

		this.body = [];
		this.elseConditional = null;

		this.isConditional = true;

	}

}

class FunctionCall {

	public var name:String;
	public var params:Array<Dynamic>;
	public var isFunctionCall:Bool;

	public function new(name:String, params:Array<Dynamic> = []) {

		this.name = name;
		this.params = params;

		this.isFunctionCall = true;

	}

}

class Return {

	public var value:Dynamic;
	public var isReturn:Bool;

	public function new(value:Dynamic) {

		this.value = value;

		this.isReturn = true;

	}

}

class Accessor {

	public var property:String;
	public var isAccessor:Bool;

	public function new(property:String) {

		this.property = property;

		this.isAccessor = true;

	}

}

class StaticElement {

	public var value:Dynamic;
	public var isStaticElement:Bool;

	public function new(value:Dynamic) {

		this.value = value;

		this.isStaticElement = true;

	}

}

class DynamicElement {

	public var value:Dynamic;
	public var isDynamicElement:Bool;

	public function new(value:Dynamic) {

		this.value = value;

		this.isDynamicElement = true;

	}

}

class AccessorElements {

	public var property:String;
	public var elements:Array<Dynamic>;
	public var isAccessorElements:Bool;

	public function new(property:String, elements:Array<Dynamic> = []) {

		this.property = property;
		this.elements = elements;

		this.isAccessorElements = true;

	}

}

class For {

	public var initialization:Dynamic;
	public var condition:Dynamic;
	public var afterthought:Dynamic;
	public var body:Array<Dynamic>;
	public var isFor:Bool;

	public function new(initialization:Dynamic, condition:Dynamic, afterthought:Dynamic) {

		this.initialization = initialization;
		this.condition = condition;
		this.afterthought = afterthought;

		this.body = [];

		this.isFor = true;

	}

}