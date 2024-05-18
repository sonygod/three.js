package three.js.examples.jsm.nodes.utils;

import three.js.core.Node;
import three.js.code.ExpressionNode;
import three.js.core.BypassNode;
import three.js.core.ContextNode;
import three.js.shadernode.ShaderNode;

class LoopNode extends Node {
    public var params:Array<Dynamic>;

    public function new(?params:Array<Dynamic>) {
        super();
        this.params = params;
    }

    public function getVarName(index:Int):String {
        return String.fromCharCode('i'.charCodeAt(0) + index);
    }

    public function getProperties(builder:Dynamic):Dynamic {
        var properties:Dynamic = builder.getNodeProperties(this);
        if (properties.stackNode != null) return properties;

        var inputs:Dynamic = {};
        for (i in 0...this.params.length - 1) {
            var param:Dynamic = this.params[i];
            var name:String = (param.isNode != true && param.name) || this.getVarName(i);
            var type:String = (param.isNode != true && param.type) || 'int';
            inputs[name] = ExpressionNode.expression(name, type);
        }

        properties.returnsNode = this.params[this.params.length - 1](inputs, builder.addStack(), builder);
        properties.stackNode = builder.removeStack();

        return properties;
    }

    public function getNodeType(builder:Dynamic):String {
        var properties:Dynamic = this.getProperties(builder);
        return properties.returnsNode != null ? properties.returnsNode.getNodeType(builder) : 'void';
    }

    public function setup(builder:Dynamic) {
        // setup properties
        this.getProperties(builder);
    }

    public function generate(builder:Dynamic):String {
        var properties:Dynamic = this.getProperties(builder);

        var contextData:Dynamic = { tempWrite: false };

        var params:Array<Dynamic> = this.params;
        var stackNode:Dynamic = properties.stackNode;

        for (i in 0...params.length - 1) {
            var param:Dynamic = params[i];

            var start:Dynamic = null, end:Dynamic = null, name:String = null, type:String = null, condition:String = null, update:String = null;

            if (param.isNode) {
                type = 'int';
                name = this.getVarName(i);
                start = '0';
                end = param.build(builder, type);
                condition = '<';
            } else {
                type = param.type || 'int';
                name = param.name || this.getVarName(i);
                start = param.start;
                end = param.end;
                condition = param.condition;
                update = param.update;

                if (Std.isOfType(start, Int)) start = Std.string(start);
                else if (start != null && start.isNode) start = start.build(builder, type);

                if (Std.isOfType(end, Int)) end = Std.string(end);
                else if (end != null && end.isNode) end = end.build(builder, type);

                if (start != null && end == null) {
                    start = start + ' - 1';
                    end = '0';
                    condition = '>=';
                } else if (end != null && start == null) {
                    start = '0';
                    condition = '<';
                }

                if (condition == null) {
                    if (Std.parseInt(start) > Std.parseInt(end)) {
                        condition = '>=';
                    } else {
                        condition = '<';
                    }
                }
            }

            var internalParam:Dynamic = { start: start, end: end, condition: condition };

            var startSnippet:String = internalParam.start;
            var endSnippet:String = internalParam.end;

            var declarationSnippet:String = '';
            var conditionalSnippet:String = '';
            var updateSnippet:String = '';

            if (update == null) {
                if (type == 'int' || type == 'uint') {
                    if (condition.indexOf('<') != -1) update = '++';
                    else update = '--';
                } else {
                    if (condition.indexOf('<') != -1) update = '+= 1.';
                    else update = '-= 1.';
                }
            }

            declarationSnippet += builder.getVar(type, name) + ' = ' + startSnippet;

            conditionalSnippet += name + ' ' + condition + ' ' + endSnippet;
            updateSnippet += name + ' ' + update;

            var forSnippet:String = 'for ( ' + declarationSnippet + '; ' + conditionalSnippet + '; ' + updateSnippet + ' )';

            builder.addFlowCode((i == 0 ? '\n' : '') + builder.tab + forSnippet + ' {\n\n').addFlowTab();
        }

        var stackSnippet:String = context(stackNode, contextData).build(builder, 'void');

        var returnsSnippet:String = properties.returnsNode != null ? properties.returnsNode.build(builder) : '';

        builder.removeFlowTab().addFlowCode('\n' + builder.tab + stackSnippet);

        for (i in 0...params.length - 1) {
            builder.addFlowCode((i == 0 ? '' : builder.tab) + '}\n\n').removeFlowTab();
        }

        builder.addFlowTab();

        return returnsSnippet;
    }
}

class LoopNodeBuilder {
    static public function loop(?params:Array<Dynamic>):Dynamic {
        return NodeObject(nodeArray(params, 'int')).append(new LoopNode(params));
    }

    static public function Continue():Dynamic {
        return ExpressionNode.expression('continue').append();
    }

    static public function Break():Dynamic {
        return ExpressionNode.expression('break').append();
    }
}

NodeElement.addNodeElement('loop', function(returns:Dynamic, ?params:Array<Dynamic>) {
    return BypassNode.bypass(returns, LoopNodeBuilder.loop(params));
});

NodeClass.addNodeClass('LoopNode', LoopNode);