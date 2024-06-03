package three.js.nodes;

import three.js.nodes.core.Node;
import three.js.nodes.core.PropertyNode;
import three.js.nodes.core.ContextNode;
import three.js.nodes.shadernode.ShaderNode;

class CondNode extends Node {

    var condNode: Node;
    var ifNode: Node;
    var elseNode: Node;

    public function new(condNode: Node, ifNode: Node, elseNode: Node = null) {
        super();
        this.condNode = condNode;
        this.ifNode = ifNode;
        this.elseNode = elseNode;
    }

    public function getNodeType(builder: Builder): String {
        var ifType: String = ifNode.getNodeType(builder);

        if (elseNode !== null) {
            var elseType: String = elseNode.getNodeType(builder);
            if (builder.getTypeLength(elseType) > builder.getTypeLength(ifType)) {
                return elseType;
            }
        }

        return ifType;
    }

    public function generate(builder: Builder, output: String): String {
        var type: String = getNodeType(builder);
        var context: Dynamic = { tempWrite: false };

        var nodeData: Dynamic = builder.getDataFromNode(this);

        if (nodeData.nodeProperty !== null) {
            return nodeData.nodeProperty;
        }

        var needsOutput: Bool = output !== 'void';
        var nodeProperty: String = needsOutput ? PropertyNode.property(type).build(builder) : '';

        nodeData.nodeProperty = nodeProperty;

        var nodeSnippet: String = ContextNode.context(condNode).build(builder, 'bool');

        builder.addFlowCode('\n${builder.tab}if (${nodeSnippet}) {\n\n').addFlowTab();

        var ifSnippet: String = ContextNode.context(ifNode, context).build(builder, type);

        if (ifSnippet != null) {
            if (needsOutput) {
                ifSnippet = nodeProperty + ' = ' + ifSnippet + ';';
            } else {
                ifSnippet = 'return ' + ifSnippet + ';';
            }
        }

        builder.removeFlowTab().addFlowCode(builder.tab + '\t' + ifSnippet + '\n\n' + builder.tab + '}');

        if (elseNode !== null) {
            builder.addFlowCode(' else {\n\n').addFlowTab();

            var elseSnippet: String = ContextNode.context(elseNode, context).build(builder, type);

            if (elseSnippet != null) {
                if (needsOutput) {
                    elseSnippet = nodeProperty + ' = ' + elseSnippet + ';';
                } else {
                    elseSnippet = 'return ' + elseSnippet + ';';
                }
            }

            builder.removeFlowTab().addFlowCode(builder.tab + '\t' + elseSnippet + '\n\n' + builder.tab + '}\n\n');
        } else {
            builder.addFlowCode('\n\n');
        }

        return builder.format(nodeProperty, type, output);
    }
}

class CondNodeWrapper {
    public static function new(condNode: Node, ifNode: Node, elseNode: Node = null): CondNode {
        return new CondNode(condNode, ifNode, elseNode);
    }
}

ShaderNode.addNodeElement('cond', CondNodeWrapper.new);
Node.addNodeClass('CondNode', CondNode);