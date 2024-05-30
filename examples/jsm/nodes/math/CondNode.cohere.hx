import Node from '../core/Node.hx';
import { property } from '../core/PropertyNode.hx';
import { context as contextNode } from '../core/ContextNode.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class CondNode extends Node {
    public condNode: Node;
    public ifNode: Node;
    public elseNode: Node;

    public function new(condNode: Node, ifNode: Node, elseNode: Node = null) {
        super();
        this.condNode = condNode;
        this.ifNode = ifNode;
        this.elseNode = elseNode;
    }

    public function getNodeType(builder: Builder): String {
        var ifType = this.ifNode.getNodeType(builder);

        if (this.elseNode != null) {
            var elseType = this.elseNode.getNodeType(builder);

            if (builder.getTypeLength(elseType) > builder.getTypeLength(ifType)) {
                return elseType;
            }
        }

        return ifType;
    }

    public function generate(builder: Builder, output: String): String {
        var type = this.getNodeType(builder);
        var context = { tempWrite: false };
        var nodeData = builder.getDataFromNode(this);

        if (nodeData.nodeProperty != null) {
            return nodeData.nodeProperty;
        }

        var ifNode = this.ifNode;
        var elseNode = this.elseNode;
        var needsOutput = output != "void";
        var nodeProperty = needsOutput ? property(type).build(builder) : "";

        nodeData.nodeProperty = nodeProperty;

        var nodeSnippet = contextNode(this.condNode/*, context*/).build(builder, "bool");

        builder.addFlowCode("\n" + builder.tab + "if (" + nodeSnippet + ") {\n\n").addFlowTab();

        var ifSnippet = contextNode(ifNode, context).build(builder, type);

        if (ifSnippet != "") {
            if (needsOutput) {
                ifSnippet = nodeProperty + " = " + ifSnippet + ";";
            } else {
                ifSnippet = "return " + ifSnippet + ";";
            }
        }

        builder.removeFlowTab().addFlowCode(builder.tab + "\t" + ifSnippet + "\n\n" + builder.tab + "}");

        if (elseNode != null) {
            builder.addFlowCode(" else {\n\n").addFlowTab();

            var elseSnippet = contextNode(elseNode, context).build(builder, type);

            if (elseSnippet != "") {
                if (needsOutput) {
                    elseSnippet = nodeProperty + " = " + elseSnippet + ";";
                } else {
                    elseSnippet = "return " + elseSnippet + ";";
                }
            }

            builder.removeFlowTab().addFlowCode(builder.tab + "\t" + elseSnippet + "\n\n" + builder.tab + "}\n\n");
        } else {
            builder.addFlowCode("\n\n");
        }

        return builder.format(nodeProperty, type, output);
    }
}

function defaultCondNode(): CondNode {
    return new CondNode(null, null, null);
}

default export defaultCondNode;
export const cond = nodeProxy(defaultCondNode);

addNodeElement("cond", cond);

addNodeClass("CondNode", CondNode);