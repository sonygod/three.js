import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class OperatorNode extends TempNode {

	public var op:String;
	public var aNode:TempNode;
	public var bNode:TempNode;

	public function new(op:String, aNode:TempNode, bNode:TempNode, params:Array<Dynamic>) {
		super();
		this.op = op;
		if (params.length > 0) {
			var finalBNode = bNode;
			for (i in 0...params.length) {
				finalBNode = new OperatorNode(op, finalBNode, params[i]);
			}
			bNode = finalBNode;
		}
		this.aNode = aNode;
		this.bNode = bNode;
	}

	public function getNodeType(builder:ShaderNode, output:Dynamic):String {
		var op = this.op;
		var aNode = this.aNode;
		var bNode = this.bNode;
		var typeA = aNode.getNodeType(builder);
		var typeB = if (typeof bNode !== 'undefined') bNode.getNodeType(builder) else null;
		if (typeA == 'void' || typeB == 'void') {
			return 'void';
		} else if (op == '%') {
			return typeA;
		} else if (op == '~' || op == '&' || op == '|' || op == '^' || op == '>>' || op == '<<') {
			return builder.getIntegerType(typeA);
		} else if (op == '!' || op == '==' || op == '&&' || op == '||' || op == '^^') {
			return 'bool';
		} else if (op == '<' || op == '>' || op == '<=' || op == '>=') {
			var typeLength = if (output) builder.getTypeLength(output) else Math.max(builder.getTypeLength(typeA), builder.getTypeLength(typeB));
			return if (typeLength > 1) `bvec${typeLength}` else 'bool';
		} else {
			if (typeA == 'float' && builder.isMatrix(typeB)) {
				return typeB;
			} else if (builder.isMatrix(typeA) && builder.isVector(typeB)) {
				return builder.getVectorFromMatrix(typeA);
			} else if (builder.isVector(typeA) && builder.isMatrix(typeB)) {
				return builder.getVectorFromMatrix(typeB);
			} else if (builder.getTypeLength(typeB) > builder.getTypeLength(typeA)) {
				return typeB;
			}
			return typeA;
		}
	}

	public function generate(builder:ShaderNode, output:Dynamic):String {
		var op = this.op;
		var aNode = this.aNode;
		var bNode = this.bNode;
		var type = this.getNodeType(builder, output);
		var typeA:String = null;
		var typeB:String = null;
		if (type != 'void') {
			typeA = aNode.getNodeType(builder);
			typeB = if (typeof bNode !== 'undefined') bNode.getNodeType(builder) else null;
			if (op == '<' || op == '>' || op == '<=' || op == '>=' || op == '==') {
				if (builder.isVector(typeA)) {
					typeB = typeA;
				} else {
					typeA = typeB = 'float';
				}
			} else if (op == '>>' || op == '<<') {
				typeA = type;
				typeB = builder.changeComponentType(typeB, 'uint');
			} else if (builder.isMatrix(typeA) && builder.isVector(typeB)) {
				typeB = builder.getVectorFromMatrix(typeA);
			} else if (builder.isVector(typeA) && builder.isMatrix(typeB)) {
				typeA = builder.getVectorFromMatrix(typeB);
			} else {
				typeA = typeB = type;
			}
		} else {
			typeA = typeB = type;
		}
		var a = aNode.build(builder, typeA);
		var b = if (typeof bNode !== 'undefined') bNode.build(builder, typeB) else null;
		var outputLength = builder.getTypeLength(output);
		var fnOpSnippet = builder.getFunctionOperator(op);
		if (output != 'void') {
			if (op == '<' && outputLength > 1) {
				return builder.format(`${builder.getMethod('lessThan')}( ${a}, ${b} )`, type, output);
			} else if (op == '<=' && outputLength > 1) {
				return builder.format(`${builder.getMethod('lessThanEqual')}( ${a}, ${b} )`, type, output);
			} else if (op == '>' && outputLength > 1) {
				return builder.format(`${builder.getMethod('greaterThan')}( ${a}, ${b} )`, type, output);
			} else if (op == '>=' && outputLength > 1) {
				return builder.format(`${builder.getMethod('greaterThanEqual')}( ${a}, ${b} )`, type, output);
			} else if (op == '!' || op == '~') {
				return builder.format(`(${op}${a})`, typeA, output);
			} else if (fnOpSnippet) {
				return builder.format(`${fnOpSnippet}( ${a}, ${b} )`, type, output);
			} else {
				return builder.format(`( ${a} ${op} ${b} )`, type, output);
			}
		} else if (typeA != 'void') {
			if (fnOpSnippet) {
				return builder.format(`${fnOpSnippet}( ${a}, ${b} )`, type, output);
			} else {
				return builder.format(`${a} ${op} ${b}`, type, output);
			}
		}
	}

	public function serialize(data:Dynamic) {
		super.serialize(data);
		data.op = this.op;
	}

	public function deserialize(data:Dynamic) {
		super.deserialize(data);
		this.op = data.op;
	}
}

class OperatorNodeProxy {
	public function new(op:String) {
		return function(aNode:TempNode, bNode:TempNode, params:Array<Dynamic>):OperatorNode {
			return new OperatorNode(op, aNode, bNode, params);
		}
	}
}

var add = new OperatorNodeProxy().new('+');
var sub = new OperatorNodeProxy().new('-');
var mul = new OperatorNodeProxy().new('*');
var div = new OperatorNodeProxy().new('/');
var remainder = new OperatorNodeProxy().new('%');
var equal = new OperatorNodeProxy().new('==');
var notEqual = new OperatorNodeProxy().new('!=');
var lessThan = new OperatorNodeProxy().new('<');
var greaterThan = new OperatorNodeProxy().new('>');
var lessThanEqual = new OperatorNodeProxy().new('<=');
var greaterThanEqual = new OperatorNodeProxy().new('>=');
var and = new OperatorNodeProxy().new('&&');
var or = new OperatorNodeProxy().new('||');
var not = new OperatorNodeProxy().new('!');
var xor = new OperatorNodeProxy().new('^^');
var bitAnd = new OperatorNodeProxy().new('&');
var bitNot = new OperatorNodeProxy().new('~');
var bitOr = new OperatorNodeProxy().new('|');
var bitXor = new OperatorNodeProxy().new('^');
var shiftLeft = new OperatorNodeProxy().new('<<');
var shiftRight = new OperatorNodeProxy().new('>>');

Node.addNodeClass('OperatorNode', OperatorNode);

ShaderNode.addNodeElement('add', add);
ShaderNode.addNodeElement('sub', sub);
ShaderNode.addNodeElement('mul', mul);
ShaderNode.addNodeElement('div', div);
ShaderNode.addNodeElement('remainder', remainder);
ShaderNode.addNodeElement('equal', equal);
ShaderNode.addNodeElement('notEqual', notEqual);
ShaderNode.addNodeElement('lessThan', lessThan);
ShaderNode.addNodeElement('greaterThan', greaterThan);
ShaderNode.addNodeElement('lessThanEqual', lessThanEqual);
ShaderNode.addNodeElement('greaterThanEqual', greaterThanEqual);
ShaderNode.addNodeElement('and', and);
ShaderNode.addNodeElement('or', or);
ShaderNode.addNodeElement('not', not);
ShaderNode.addNodeElement('xor', xor);
ShaderNode.addNodeElement('bitAnd', bitAnd);
ShaderNode.addNodeElement('bitNot', bitNot);
ShaderNode.addNodeElement('bitOr', bitOr);
ShaderNode.addNodeElement('bitXor', bitXor);
ShaderNode.addNodeElement('shiftLeft', shiftLeft);
ShaderNode.addNodeElement('shiftRight', shiftRight);