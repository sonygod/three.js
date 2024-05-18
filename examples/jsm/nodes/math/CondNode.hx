package three.js.examples.jsm.nodes.math;

import three.js.core.Node;
import three.js.core.PropertyNode;
import three.js.core.ContextNode;
import three.js.shadernode.ShaderNode;

class CondNode extends Node {

    public var condNode:Dynamic;
    public var ifNode:Dynamic;
    public var elseNode:Dynamic;

    public function new(condNode:Dynamic, ifNode:Dynamic, ?elseNode:Dynamic) {
        super();
        this.condNode = condNode;
        this.ifNode = ifNode;
        this.elseNode = elseNode;
    }

    public function getNodeType(builder:Dynamic):Dynamic {
        var ifType:Dynamic = ifNode.getNodeType(builder);
        if (elseNode != null) {
            var elseType:Dynamic = elseNode.getNodeType(builder);
            if (builder.getTypeLength(elseType) > builder.getTypeLength(ifType)) {
                return elseType;
            }
        }
        return ifType;
    }

    public function generate(builder:Dynamic, output:String):String {
        var type:Dynamic = getNodeType(builder);
        var context:Dynamic = { tempWrite: false };
        var nodeData:Dynamic = builder.getDataFromNode(this);

        if (nodeData.nodeProperty != null) {
            return nodeData.nodeProperty;
        }

        var ifNode:Dynamic = this.ifNode;
        var elseNode:Dynamic = this.elseNode;
        var needsOutput:Bool = output != 'void';
        var nodeProperty:String = needsOutput ? PropertyNode.build(builder, type) : '';

        nodeData.nodeProperty = nodeProperty;

        var nodeSnippet:String = ContextNode.build(builder, condNode, context, 'bool');

        builder.addFlowCode('\n' + builder.tab + 'if (' + nodeSnippet + ') {\n\n').addFlowTab();

        var ifSnippet:String = ContextNode.build(builder, ifNode, context, type);

        if (ifSnippet != null) {
            if (needsOutput) {
                ifSnippet = nodeProperty + ' = ' + ifSnippet + ';';
            } else {
                ifSnippet = 'return ' + ifSnippet + ';';
            }
        }

        builder.removeFlowTab().addFlowCode(builder.tab + '\t' + ifSnippet + '\n\n' + builder.tab + '}\n');

        if (elseNode != null) {
            builder.addFlowCode(' else {\n\n').addFlowTab();

            var elseSnippet:String = ContextNode.build(builder, elseNode, context, type);

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

class CondNodeProxy {
    public static function nodeProxy(node:CondNode):Dynamic {
        return node;
    }
}

function addNodeElement(name:String, node:CondNode):Void {
    // implementation omitted
}

function addNodeClass(name:String, nodeClass:Class<CondNode>):Void {
    // implementation omitted
}

addNodeElement('cond', CondNodeProxy.nodeProxy(new CondNode(null, null)));
addNodeClass('CondNode', CondNode);