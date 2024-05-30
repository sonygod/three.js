import Node from '../core/Node';
import { expression } from '../code/ExpressionNode';
import { bypass } from '../core/BypassNode';
import { context } from '../core/ContextNode';
import { addNodeElement, nodeObject, nodeArray } from '../shadernode/ShaderNode';

class LoopNode extends Node {
    public var params:Array<Dynamic>;

    public function new(params:Array<Dynamic> = []) {
        super();
        this.params = params;
    }

    public function getVarName(index:Int):String {
        return String.fromCharCode('i'.charCodeAt() + index);
    }

    public function getProperties(builder:Dynamic):Dynamic {
        var properties = builder.getNodeProperties(this);

        if (properties.stackNode != null) {
            return properties;
        }

        var inputs:Dynamic = {};
        for (i in 0...(this.params.length - 1)) {
            var param = this.params[i];
            var name = (Std.is(param, Node) != true && param.name) or this.getVarName(i);
            var type = (Std.is(param, Node) != true && param.type) or 'Int';
            inputs[name] = expression(name, type);
        }

        properties.returnsNode = this.params[this.params.length - 1].call(inputs, builder.addStack(), builder);
        properties.stackNode = builder.removeStack();

        return properties;
    }

    public function getNodeType(builder:Dynamic):String {
        var properties = this.getProperties(builder);
        var returnsNode = properties.returnsNode;
        if (returnsNode != null) {
            return returnsNode.getNodeType(builder);
        } else {
            return 'Void';
        }
    }

    public function setup(builder:Dynamic):Void {
        this.getProperties(builder);
    }

    public function generate(builder:Dynamic):String {
        var properties = this.getProperties(builder);
        var contextData = { tempWrite: false };
        var params = this.params;
        var stackNode = properties.stackNode;

        for (i in 0...(params.length - 1)) {
            var param = params[i];
            var start:Dynamic, end:Dynamic, name:Dynamic, type:Dynamic, condition:Dynamic, update:Dynamic;

            if (Std.is(param, Node)) {
                type = 'Int';
                name = this.getVarName(i);
                start = '0';
                end = param.build(builder, type);
                condition = '<';
            } else {
                type = param.type or 'Int';
                name = param.name or this.getVarName(i);
                start = param.start;
                end = param.end;
                condition = param.condition;
                update = param.update;

                if (Std.is(start, Int)) {
                    start = start.toString();
                } else if (start != null && Std.is(start, Node)) {
                    start = start.build(builder, type);
                }

                if (Std.is(end, Int)) {
                    end = end.toString();
                } else if (end != null && Std.is(end, Node)) {
                    end = end.build(builder, type);
                }

                if (start != null && end == null) {
                    start = start + ' - 1';
                    end = '0';
                    condition = '>=';
                } else if (end != null && start == null) {
                    start = '0';
                    condition = '<';
                }

                if (condition == null) {
                    if (start > end) {
                        condition = '>=';
                    } else {
                        condition = '<';
                    }
                }
            }

            var internalParam = { start, end, condition };

            var startSnippet = internalParam.start;
            var endSnippet = internalParam.end;

            var declarationSnippet = '';
            var conditionalSnippet = '';
            var updateSnippet = '';

            if (update == null) {
                if (type == 'Int' || type == 'UInt') {
                    if (condition.indexOf('<') != -1) {
                        update = '++';
                    } else {
                        update = '--';
                    }
                } else {
                    if (condition.indexOf('<') != -1) {
                        update = '+= 1.';
                    } else {
                        update = '-= 1.';
                    }
                }
            }

            declarationSnippet += builder.getVar(type, name) + ' = ' + startSnippet;
            conditionalSnippet += name + ' ' + condition + ' ' + endSnippet;
            updateSnippet += name + ' ' + update;

            var forSnippet = 'for (${declarationSnippet}; ${conditionalSnippet}; ${updateSnippet})';

            builder.addFlowCode((i == 0 ? '\n' : '') + builder.tab + forSnippet + ' {\n\n').addFlowTab();
        }

        var stackSnippet = context(stackNode, contextData).build(builder, 'Void');
        var returnsSnippet = properties.returnsNode != null ? properties.returnsNode.build(builder) : '';

        builder.removeFlowTab().addFlowCode('\n' + builder.tab + stackSnippet);

        for (i in 0...(this.params.length - 1)) {
            builder.addFlowCode((i == 0 ? '' : builder.tab) + '}\n\n').removeFlowTab();
        }

        builder.addFlowTab();

        return returnsSnippet;
    }
}

@:export
var LoopNode:LoopNode = LoopNode;

@:export
function loop(...params):Dynamic {
    return nodeObject(new LoopNode(nodeArray(params, 'Int'))).append();
}

@:export
function Continue():Dynamic {
    return expression('continue').append();
}

@:export
function Break():Dynamic {
    return expression('break').append();
}

addNodeElement('loop', function(returns, ...params) {
    return bypass(returns, loop(...params));
});

addNodeClass('LoopNode', LoopNode);