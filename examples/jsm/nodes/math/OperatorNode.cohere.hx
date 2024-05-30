import TempNode from '../core/TempNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class OperatorNode extends TempNode {
    public var op:String;
    public var aNode:TempNode;
    public var bNode:TempNode;

    public function new(op:String, aNode:TempNode, bNode:TempNode, ...params:Array<TempNode>) {
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

    public function getNodeType(builder:Dynamic, output:Dynamic):Dynamic {
        var op = this.op;
        var aNode = this.aNode;
        var bNode = this.bNode;
        var typeA = aNode.getNodeType(builder);
        var typeB = if (bNode != null) bNode.getNodeType(builder) else null;
        if (typeA == 'void' || typeB == 'void') {
            return 'void';
        } else if (op == '%') {
            return typeA;
        } else if (['~', '&', '|', '^', '>>', '<<'].contains(op)) {
            return builder.getIntegerType(typeA);
        } else if (['!', '==', '&&', '||', '^^'].contains(op)) {
            return 'bool';
        } else if (['<', '>', '<=', '>='].contains(op)) {
            var typeLength = if (output != null) builder.getTypeLength(output) else Math.max(builder.getTypeLength(typeA), builder.getTypeLength(typeB));
            return if (typeLength > 1) 'bvec' + typeLength else 'bool';
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

    public function generate(builder:Dynamic, output:Dynamic):Dynamic {
        var op = this.op;
        var aNode = this.aNode;
        var bNode = this.bNode;
        var type = this.getNodeType(builder, output);
        var typeA:Dynamic, typeB:Dynamic;
        if (type != 'void') {
            typeA = aNode.getNodeType(builder);
            typeB = if (bNode != null) bNode.getNodeType(builder) else null;
            if (['<', '>', '<=', '>=', '=='].contains(op)) {
                if (builder.isVector(typeA)) {
                    typeB = typeA;
                } else {
                    typeA = typeB = 'float';
                }
            } else if (['>>', '<<'].contains(op)) {
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
        var b = if (bNode != null) bNode.build(builder, typeB) else null;
        var outputLength = builder.getTypeLength(output);
        var fnOpSnippet = builder.getFunctionOperator(op);
        if (output != 'void') {
            if (op == '<' && outputLength > 1) {
                return builder.format("${builder.getMethod('lessThan')}( ${a}, ${b} )", type, output);
            } else if (op == '<=' && outputLength > 1) {
                return builder.format("${builder.getMethod('lessThanEqual')}( ${a}, ${b} )", type, output);
            } else if (op == '>' && outputLength > 1) {
                return builder.format("${builder.getMethod('greaterThan')}( ${a}, ${b} )", type, output);
            } else if (op == '>=' && outputLength > 1) {
                return builder.format("${builder.getMethod('greaterThanEqual')}( ${a}, ${b} )", type, output);
            } else if (['!', '~'].contains(op)) {
                return builder.format("(${op}${a})", typeA, output);
            } else if (fnOpSnippet != null) {
                return builder.format("${fnOpSnippet}( ${a}, ${b} )", type, output);
            } else {
                return builder.format("(${a} ${op} ${b})", type, output);
            }
        } else if (typeA != 'void') {
            if (fnOpSnippet != null) {
                return builder.format("${fnOpSnippet}( ${a}, ${b} )", type, output);
            } else {
                return builder.format("${a} ${op} ${b}", type, output);
            }
        }
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.op = this.op;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.op = data.op;
    }
}

@:default
class OperatorNodeExport {
    public static inline function add(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('+', a, b);
    }

    public static inline function sub(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('-', a, b);
    }

    public static inline function mul(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('*', a, b);
    }

    public static inline function div(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('/', a, b);
    }

    public static inline function remainder(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('%', a, b);
    }

    public static inline function equal(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('==', a, b);
    }

    public static inline function notEqual(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('!=', a, b);
    }

    public static inline function lessThan(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('<', a, b);
    }

    public static inline function greaterThan(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('>', a, b);
    }

    public static inline function lessThanEqual(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('<=', a, b);
    }

    public static inline function greaterThanEqual(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('>=', a, b);
    }

    public static inline function and(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('&&', a, b);
    }

    public static inline function or(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('||', a, b);
    }

    public static inline function not(a:TempNode):OperatorNode {
        return new OperatorNode('!', null, a);
    }

    public static inline function xor(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('^^', a, b);
    }

    public static inline function bitAnd(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('&', a, b);
    }

    public static inline function bitNot(a:TempNode):OperatorNode {
        return new OperatorNode('~', null, a);
    }

    public static inline function bitOr(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('|', a, b);
    }

    public static inline function bitXor(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('^', a, b);
    }

    public static inline function shiftLeft(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('<<', a, b);
    }

    public static inline function shiftRight(a:TempNode, b:TempNode):OperatorNode {
        return new OperatorNode('>>', a, b);
    }
}

addNodeElement('add', OperatorNodeExport.add);
addNodeElement('sub', OperatorNodeExport.sub);
addNodeElement('mul', OperatorNodeExport.mul);
addNodeElement('div', OperatorNodeExport.div);
addNodeElement('remainder', OperatorNodeExport.remainder);
addNodeElement('equal', OperatorNodeExport.equal);
addNodeElement('notEqual', OperatorNodeExport.notEqual);
addNodeElement('lessThan', OperatorNodeExport.lessThan);
addNodeElement('greaterThan', OperatorNodeExport.greaterThan);
addNodeElement('lessThanEqual', OperatorNodeExport.lessThanEqual);
addNodeElement('greaterThanEqual', OperatorNodeExport.greaterThanEqual);
addNodeElement('and', OperatorNodeExport.and);
addNodeElement('or', OperatorNodeExport.or);
addNodeElement('not', OperatorNodeExport.not);
addNodeElement('xor', OperatorNodeExport.xor);
addNodeElement('bitAnd', OperatorNodeExport.bitAnd);
addNodeElement('bitNot', OperatorNodeExport.bitNot);
addNodeElement('bitOr', OperatorNodeExport.bitOr);
addNodeElement('bitXor', OperatorNodeExport.bitXor);
addNodeElement('shiftLeft', OperatorNodeExport.shiftLeft);
addNodeElement('shiftRight', OperatorNodeExport.shiftRight);

addNodeClass('OperatorNode', OperatorNode);