import node.Node;
import node.TempNode;
import shadernode.ShaderNode;
import core.constants;

class AssignNode extends TempNode {

    public var targetNode:Node;
    public var sourceNode:Node;

    public function new(targetNode:Node, sourceNode:Node) {
        super();
        this.targetNode = targetNode;
        this.sourceNode = sourceNode;
    }

    public function hasDependencies():Bool {
        return false;
    }

    public function getNodeType(builder:ShaderNode, output:String):String {
        return output != "void" ? targetNode.getNodeType(builder) : "void";
    }

    public function needsSplitAssign(builder:ShaderNode):Bool {
        if (builder.isAvailable("swizzleAssign") == false && targetNode.isSplitNode && targetNode.components.length > 1) {
            var targetLength = builder.getTypeLength(targetNode.node.getNodeType(builder));
            var assignDiferentVector = constants.vectorComponents.join("").substr(0, targetLength) != targetNode.components;
            return assignDiferentVector;
        }
        return false;
    }

    public function generate(builder:ShaderNode, output:String):String {
        var needsSplitAssign = this.needsSplitAssign(builder);
        var targetType = targetNode.getNodeType(builder);
        var target = targetNode.context({assign: true}).build(builder);
        var source = sourceNode.build(builder, targetType);
        var sourceType = sourceNode.getNodeType(builder);
        var nodeData = builder.getDataFromNode(this);

        var snippet:String;

        if (nodeData.initialized) {
            if (output != "void") {
                snippet = target;
            }
        } else if (needsSplitAssign) {
            var sourceVar = builder.getVarFromNode(this, null, targetType);
            var sourceProperty = builder.getPropertyName(sourceVar);
            builder.addLineFlowCode("${sourceProperty} = ${source}");
            var targetRoot = targetNode.node.context({assign: true}).build(builder);
            for (i in 0...targetNode.components.length) {
                var component = targetNode.components[i];
                builder.addLineFlowCode("${targetRoot}.${component} = ${sourceProperty}[${i}]");
            }
            if (output != "void") {
                snippet = target;
            }
        } else {
            snippet = "${target} = ${source}";
            if (output == "void" || sourceType == "void") {
                builder.addLineFlowCode(snippet);
                if (output != "void") {
                    snippet = target;
                }
            }
        }

        nodeData.initialized = true;

        return builder.format(snippet, targetType, output);
    }
}

class AssignNodeProxy extends ShaderNode.Proxy<AssignNode> {
    public function new() {
        super(AssignNode);
    }
}

var assign = new AssignNodeProxy();

Node.addNodeClass("AssignNode", AssignNode);
ShaderNode.addNodeElement("assign", assign);