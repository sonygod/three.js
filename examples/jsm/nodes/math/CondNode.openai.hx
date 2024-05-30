package three.js.nodes.math;

import three.js.nodes.core.Node;
import three.js.nodes.core.PropertyNode;
import three.js.nodes.core.ContextNode;
import three.js.nodes.shader.ShaderNode;

class CondNode extends Node {

    public var condNode:Node;
    public var ifNode:Node;
    public var elseNode:Node;

    public function new(condNode:Node, ifNode:Node, elseNode:Node = null) {
        super();
        this.condNode = condNode;
        this.ifNode = ifNode;
        this.elseNode = elseNode;
    }

    override public function getNodeType(builder:Dynamic):String {
        var ifType = ifNode.getNodeType(builder);
        if (elseNode != null) {
            var elseType = elseNode.getNodeType(builder);
            if (builder.getTypeLength(elseType) > builder.getTypeLength(ifType)) {
                return elseType;
            }
        }
        return ifType;
    }

    override public function generate(builder:Dynamic, output:String):String {
        var type = getNodeType(builder);
        var context = { tempWrite: false };
        var nodeData = builder.getDataFromNode(this);

        if (nodeData.nodeProperty != null) {
            return nodeData.nodeProperty;
        }

        var ifNode = this.ifNode;
        var elseNode = this.elseNode;
        var needsOutput = output != 'void';
        var nodeProperty = needsOutput ? PropertyNode.property(type).build(builder) : '';

        nodeData.nodeProperty = nodeProperty;

        var nodeSnippet = ContextNode.context(condNode/*, context*/).build(builder, 'bool');
        builder.addFlowCode('\n${builder.tab}if (${nodeSnippet}) {\n\n').addFlowTab();

        var ifSnippet = ContextNode.context(ifNode, context).build(builder, type);
        if (ifSnippet != null) {
            if (needsOutput) {
                ifSnippet = nodeProperty + ' = ' + ifSnippet + ';';
            } else {
                ifSnippet = 'return ' + ifSnippet + ';';
            }
        }

        builder.removeFlowTab().addFlowCode(builder.tab + '\t' + ifSnippet + '\n\n' + builder.tab + '}');

        if (elseNode != null) {
            builder.addFlowCode(' else {\n\n').addFlowTab();
            var elseSnippet = ContextNode.context(elseNode, context).build(builder, type);
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

// Expose the CondNode class
extern class CondNode {

    @:native('cond')
    static var cond(get, never):Node;

    static function get_cond():Node {
        return nodeProxy(CondNode);
    }
}

// Add the CondNode to the node registry
ShaderNode.addNodeElement('cond', CondNode.cond);
ShaderNode.addNodeClass('CondNode', CondNode);