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

    public function getNodeType(builder:Dynamic, output:String):String {
        var typeA = aNode.getNodeType(builder);
        var typeB = (bNode != null) ? bNode.getNodeType(builder) : null;

        if (typeA == 'void' || typeB == 'void') {
            return 'void';
        } else if (op == '%') {
            return typeA;
        } else if (op == '~' || op == '&' || op == '|' || op == '^' || op == '>>' || op == '<<') {
            return builder.getIntegerType(typeA);
        } else if (op == '!' || op == '==' || op == '&&' || op == '||' || op == '^^') {
            return 'bool';
        } else if (op == '<' || op == '>' || op == '<=' || op == '>=') {
            var typeLength = (output != null) ? builder.getTypeLength(output) : Math.max(builder.getTypeLength(typeA), builder.getTypeLength(typeB));
            return (typeLength > 1) ? 'bvec' + typeLength : 'bool';
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

    public function generate(builder:Dynamic, output:String):String {
        var type = this.getNodeType(builder, output);
        var typeA = (type != 'void') ? aNode.getNodeType(builder) : type;
        var typeB = (type != 'void' && bNode != null) ? bNode.getNodeType(builder) : type;

        if (type != 'void') {
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
        }

        var a = aNode.build(builder, typeA);
        var b = (bNode != null) ? bNode.build(builder, typeB) : null;
        var outputLength = builder.getTypeLength(output);
        var fnOpSnippet = builder.getFunctionOperator(op);

        if (output != 'void') {
            if (op == '<' && outputLength > 1) {
                return builder.format(builder.getMethod('lessThan') + '(' + a + ', ' + b + ')', type, output);
            } else if (op == '<=' && outputLength > 1) {
                return builder.format(builder.getMethod('lessThanEqual') + '(' + a + ', ' + b + ')', type, output);
            } else if (op == '>' && outputLength > 1) {
                return builder.format(builder.getMethod('greaterThan') + '(' + a + ', ' + b + ')', type, output);
            } else if (op == '>=' && outputLength > 1) {
                return builder.format(builder.getMethod('greaterThanEqual') + '(' + a + ', ' + b + ')', type, output);
            } else if (op == '!' || op == '~') {
                return builder.format('(' + op + a + ')', typeA, output);
            } else if (fnOpSnippet != null) {
                return builder.format(fnOpSnippet + '(' + a + ', ' + b + ')', type, output);
            } else {
                return builder.format('(' + a + ' ' + op + ' ' + b + ')', type, output);
            }
        } else if (typeA != 'void') {
            if (fnOpSnippet != null) {
                return builder.format(fnOpSnippet + '(' + a + ', ' + b + ')', type, output);
            } else {
                return builder.format(a + ' ' + op + ' ' + b, type, output);
            }
        }
        return null;
    }

    public override function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.op = this.op;
    }

    public override function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.op = data.op;
    }
}

var nodes:Array<String> = ["+", "-", "*", "/", "%", "==", "!=", "<", ">", "<=", ">=", "&&", "||", "!", "^^", "&", "~", "|", "^", "<<", ">>"];

for (node in nodes) {
    var nodeName:String = Node.getNodeName(node);
    var nodeFunc:Function = function(aNode:TempNode, bNode:TempNode, params:Array<Dynamic>) {
        return new OperatorNode(node, aNode, bNode, params);
    }
    ShaderNode.addNodeElement(nodeName, nodeFunc);
    Node.addNodeClass(nodeName + 'Node', OperatorNode);
}