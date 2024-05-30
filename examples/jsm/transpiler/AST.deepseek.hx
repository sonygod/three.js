class Program {

	var body:Array<Dynamic>;
	var isProgram:Bool;

	public function new() {

		this.body = [];

		this.isProgram = true;

	}

}

class VariableDeclaration {

	var type:Dynamic;
	var name:Dynamic;
	var value:Dynamic;
	var next:Dynamic;
	var immutable:Bool;
	var isVariableDeclaration:Bool;

	public function new(type:Dynamic, name:Dynamic, value:Dynamic = null, next:Dynamic = null, immutable:Bool = false) {

		this.type = type;
		this.name = name;
		this.value = value;
		this.next = next;

		this.immutable = immutable;

		this.isVariableDeclaration = true;

	}

}

class Uniform {

	var type:Dynamic;
	var name:Dynamic;
	var isUniform:Bool;

	public function new(type:Dynamic, name:Dynamic) {

		this.type = type;
		this.name = name;

		this.isUniform = true;

	}

}

class Varying {

	var type:Dynamic;
	var name:Dynamic;
	var isVarying:Bool;

	public function new(type:Dynamic, name:Dynamic) {

		this.type = type;
		this.name = name;

		this.isVarying = true;

	}

}

class FunctionParameter {

	var type:Dynamic;
	var name:Dynamic;
	var qualifier:Dynamic;
	var immutable:Bool;
	var isFunctionParameter:Bool;

	public function new(type:Dynamic, name:Dynamic, qualifier:Dynamic = null, immutable:Bool = true) {

		this.type = type;
		this.name = name;
		this.qualifier = qualifier;
		this.immutable = immutable;

		this.isFunctionParameter = true;

	}

}

class FunctionDeclaration {

	var type:Dynamic;
	var name:Dynamic;
	var params:Array<Dynamic>;
	var body:Array<Dynamic>;
	var isFunctionDeclaration:Bool;

	public function new(type:Dynamic, name:Dynamic, params:Array<Dynamic> = []) {

		this.type = type;
		this.name = name;
		this.params = params;
		this.body = [];

		this.isFunctionDeclaration = true;

	}

}

class Expression {

	var expression:Dynamic;
	var isExpression:Bool;

	public function new(expression:Dynamic) {

		this.expression = expression;

		this.isExpression = true;

	}

}

class Ternary {

	var cond:Dynamic;
	var left:Dynamic;
	var right:Dynamic;
	var isTernary:Bool;

	public function new(cond:Dynamic, left:Dynamic, right:Dynamic) {

		this.cond = cond;
		this.left = left;
		this.right = right;

		this.isTernary = true;

	}

}

class Operator {

	var type:Dynamic;
	var left:Dynamic;
	var right:Dynamic;
	var isOperator:Bool;

	public function new(type:Dynamic, left:Dynamic, right:Dynamic) {

		this.type = type;
		this.left = left;
		this.right = right;

		this.isOperator = true;

	}

}

class Unary {

	var type:Dynamic;
	var expression:Dynamic;
	var after:Bool;
	var isUnary:Bool;

	public function new(type:Dynamic, expression:Dynamic, after:Bool = false) {

		this.type = type;
		this.expression = expression;
		this.after = after;

		this.isUnary = true;

	}

}

class Number {

	var type:String;
	var value:Dynamic;
	var isNumber:Bool;

	public function new(value:Dynamic, type:String = 'float') {

		this.type = type;
		this.value = value;

		this.isNumber = true;

	}

}

class String {

	var value:Dynamic;
	var isString:Bool;

	public function new(value:Dynamic) {

		this.value = value;

		this.isString = true;

	}

}

class Conditional {

	var cond:Dynamic;
	var body:Array<Dynamic>;
	var elseConditional:Dynamic;
	var isConditional:Bool;

	public function new(cond:Dynamic = null) {

		this.cond = cond;

		this.body = [];
		this.elseConditional = null;

		this.isConditional = true;

	}

}

class FunctionCall {

	var name:Dynamic;
	var params:Array<Dynamic>;
	var isFunctionCall:Bool;

	public function new(name:Dynamic, params:Array<Dynamic> = []) {

		this.name = name;
		this.params = params;

		this.isFunctionCall = true;

	}

}

class Return {

	var value:Dynamic;
	var isReturn:Bool;

	public function new(value:Dynamic) {

		this.value = value;

		this.isReturn = true;

	}

}

class Accessor {

	var property:Dynamic;
	var isAccessor:Bool;

	public function new(property:Dynamic) {

		this.property = property;

		this.isAccessor = true;

	}

}

class StaticElement {

	var value:Dynamic;
	var isStaticElement:Bool;

	public function new(value:Dynamic) {

		this.value = value;

		this.isStaticElement = true;

	}

}

class DynamicElement {

	var value:Dynamic;
	var isDynamicElement:Bool;

	public function new(value:Dynamic) {

		this.value = value;

		this.isDynamicElement = true;

	}

}

class AccessorElements {

	var property:Dynamic;
	var elements:Array<Dynamic>;
	var isAccessorElements:Bool;

	public function new(property:Dynamic, elements:Array<Dynamic> = []) {

		this.property = property;
		this.elements = elements;

		this.isAccessorElements = true;

	}

}

class For {

	var initialization:Dynamic;
	var condition:Dynamic;
	var afterthought:Dynamic;
	var body:Array<Dynamic>;
	var isFor:Bool;

	public function new(initialization:Dynamic, condition:Dynamic, afterthought:Dynamic) {

		this.initialization = initialization;
		this.condition = condition;
		this.afterthought = afterthought;

		this.body = [];

		this.isFor = true;

	}

}