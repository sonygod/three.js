package three.js.examples.jsm.nodes.math;

import three.js.examples.core.TempNode;
import three.js.examples.core.Node;
import three.js.examples.shadernode.ShaderNode;

class OperatorNode extends TempNode {
    public var op:String;

    public function new(op:String, aNode:TempNode, bNode:TempNode, params:Array<TempNode> = null) {
        super();
        this.op = op;
        if (params != null && params.length > 0) {
            var finalBNode:TempNode = bNode;
            for (i in 0...params.length) {
                finalBNode = new OperatorNode(op, finalBNode, params[i]);
            }
            bNode = finalBNode;
        }
        this.aNode = aNode;
        this.bNode = bNode;
    }

    override public function getNodeType(builder:Dynamic, output:Dynamic):String {
        var op:String = this.op;
        var aNode:TempNode = this.aNode;
        var bNode:TempNode = this.bNode;

        var typeA:String = aNode.getNodeType(builder);
        var typeB:String = if (bNode != null) bNode.getNodeType(builder) else null;

        if (typeA == 'void' || typeB == 'void') {
            return 'void';
        } else if (op == '%') {
            return typeA;
        } else if (op == '~' || op == '&' || op == '|' || op == '^' || op == '>>' || op == '<<') {
            return builder.getIntegerType(typeA);
        } else if (op == '!' || op == '==' || op == '&&' || op == '||' || op == '^^') {
            return 'bool';
        } else if (op == '<' || op == '>' || op == '<=' || op == '>=') {
            var typeLength:Int = if (output != null) builder.getTypeLength(output) else Math.max(builder.getTypeLength(typeA), builder.getTypeLength(typeB));
            return typeLength > 1 ? 'bvec$typeLength' : 'bool';
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

    override public function generate(builder:Dynamic, output:Dynamic):String {
        var op:String = this.op;
        var aNode:TempNode = this.aNode;
        var bNode:TempNode = this.bNode;

        var type:String = this.getNodeType(builder, output);

        var typeA:String = null;
        var typeB:String = null;

        if (type != 'void') {
            typeA = aNode.getNodeType(builder);
            typeB = if (bNode != null) bNode.getNodeType(builder) else null;

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

        var a:String = aNode.build(builder, typeA);
        var b:String = if (bNode != null) bNode.build(builder, typeB) else null;

        var outputLength:Int = builder.getTypeLength(output);
        var fnOpSnippet:String = builder.getFunctionOperator(op);

        if (output != 'void') {
            if (op == '<' && outputLength > 1) {
                return builder.format('${builder.getMethod("lessThan")}( ${a}, ${b} )', type, output);
            } else if (op == '<=' && outputLength > 1) {
                return builder.format('${builder.getMethod("lessThanEqual")} ( ${a}, ${b} )', type, output);
            } else if (op == '>' && outputLength > 1) {
                return builder.format('${builder.getMethod("greaterThan")} ( ${a}, ${b} )', type, output);
            } else if (op == '>=' && outputLength > 1) {
                return builder.format('${builder.getMethod("greaterThanEqual")} ( ${a}, ${b} )', type, output);
            } else if (op == '!' || op == '~') {
                return builder.format('(${op}${a})', typeA, output);
            } else if (fnOpSnippet != null) {
                return builder.format('${fnOpSnippet}( ${a}, ${b} )', type, output);
            } else {
                return builder.format('(${a} ${op} ${b})', type, output);
            }
        } else if (typeA != 'void') {
            if (fnOpSnippet != null) {
                return builder.format('${fnOpSnippet}( ${a}, ${b} )', type, output);
            } else {
                return builder.format('${a} ${op} ${b}', type, output);
            }
        }
    }

    override public function serialize(data:Dynamic) {
        super.serialize(data);
        data.op = this.op;
    }

    override public function deserialize(data:Dynamic) {
        super.deserialize(data);
        this.op = data.op;
    }
}

class NodeProxy {
    public static function nodeProxy(nodeClass:Class<OperatorNode>, op:String):Class<OperatorNode> {
        return Type.createInstance(nodeClass, [op, null, null]);
    }
}

class AddNode extends OperatorNode {
    public function new(aNode:TempNode, bNode:TempNode, params:Array<TempNode> = null) {
        super('+', aNode, bNode, params);
    }
}

// ... and so on for each operator node ...

// export nodes
var add = NodeProxy.nodeProxy(AddNode, '+');
var sub = NodeProxy.nodeProxy(OperatorNode, '-');
var mul = NodeProxy.nodeProxy(OperatorNode, '*');
var div = NodeProxy.nodeProxy(OperatorNode, '/');
var remainder = NodeProxy.nodeProxy(OperatorNode, '%');
var equal = NodeProxy.nodeProxy(OperatorNode, '==');
var notEqual = NodeProxy.nodeProxy(OperatorNode, '!=');
var lessThan = NodeProxy.nodeProxy(OperatorNode, '<');
var greaterThan = NodeProxy.nodeProxy(OperatorNode, '>');
var lessThanEqual = NodeProxy.nodeProxy(OperatorNode, '<=');
var greaterThanEqual = NodeProxy.nodeProxy(OperatorNode, '>=');
var and = NodeProxy.nodeProxy(OperatorNode, '&&');
var or = NodeProxy.nodeProxy(OperatorNode, '||');
var not = NodeProxy.nodeProxy(OperatorNode, '!');
var xor = NodeProxy.nodeProxy(OperatorNode, '^^');
var bitAnd = NodeProxy.nodeProxy(OperatorNode, '&');
var bitNot = NodeProxy.nodeProxy(OperatorNode, '~');
var bitOr = NodeProxy.nodeProxy(OperatorNode, '|');
var bitXor = NodeProxy.nodeProxy(OperatorNode, '^');
var shiftLeft = NodeProxy.nodeProxy(OperatorNode, '<<');
var shiftRight = NodeProxy.nodeProxy(OperatorNode, '>>');

// add nodes to registry
addNodeElement('add', add);
addNodeElement('sub', sub);
addNodeElement('mul', mul);
addNodeElement('div', div);
addNodeElement('remainder', remainder);
addNodeElement('equal', equal);
addNodeElement('notEqual', notEqual);
addNodeElement('lessThan', lessThan);
addNodeElement('greaterThan', greaterThan);
addNodeElement('lessThanEqual', lessThanEqual);
addNodeElement('greaterThanEqual', greaterThanEqual);
addNodeElement('and', and);
addNodeElement('or', or);
addNodeElement('not', not);
addNodeElement('xor', xor);
addNodeElement('bitAnd', bitAnd);
addNodeElement('bitNot', bitNot);
addNodeElement('bitOr', bitOr);
addNodeElement('bitXor', bitXor);
addNodeElement('shiftLeft', shiftLeft);
addNodeElement('shiftRight', shiftRight);

addNodeClass('OperatorNode', OperatorNode);