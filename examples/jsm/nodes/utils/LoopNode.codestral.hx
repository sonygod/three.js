import js.Browser.document;
import js.html.HTMLDocument;
import js.html.HTMLElement;

import Node from '../core/Node';
import ExpressionNode from '../code/ExpressionNode';
import BypassNode from '../core/BypassNode';
import ContextNode from '../core/ContextNode';
import ShaderNode from '../shadernode/ShaderNode';

class LoopNode extends Node {

    public var params: Array<Dynamic> = [];

    public function new(params: Array<Dynamic> = null) {
        super();
        if (params != null) this.params = params;
    }

    public function getVarName(index: Int): String {
        return String.fromCodePoint('i'.codePointAt(0) + index);
    }

    public function getProperties(builder: Dynamic): Dynamic {
        var properties = builder.getNodeProperties(this);

        if (properties.stackNode != null) return properties;

        var inputs = new haxe.ds.StringMap<Dynamic>();

        for (i in 0...this.params.length - 1) {
            var param = this.params[i];

            var name: String;
            var type: String;

            if (Std.is(param, Node)) {
                name = this.getVarName(i);
                type = 'Int';
            } else {
                name = param.name || this.getVarName(i);
                type = param.type || 'Int';
            }

            inputs.set(name, new ExpressionNode(name, type));
        }

        properties.returnsNode = this.params[this.params.length - 1](inputs, builder.addStack(), builder);
        properties.stackNode = builder.removeStack();

        return properties;
    }

    public function getNodeType(builder: Dynamic): String {
        var properties = this.getProperties(builder);

        if (properties.returnsNode != null) return properties.returnsNode.getNodeType(builder);
        else return 'Void';
    }

    public function setup(builder: Dynamic): Void {
        this.getProperties(builder);
    }

    public function generate(builder: Dynamic): String {
        var properties = this.getProperties(builder);

        var contextData = { tempWrite: false };

        var params = this.params;
        var stackNode = properties.stackNode;

        for (i in 0...params.length - 1) {
            var param = params[i];

            var start: String = null;
            var end: String = null;
            var name: String = null;
            var type: String = null;
            var condition: String = null;
            var update: String = null;

            if (Std.is(param, Node)) {
                type = 'Int';
                name = this.getVarName(i);
                start = '0';
                end = param.build(builder, type);
                condition = '<';
            } else {
                type = param.type || 'Int';
                name = param.name || this.getVarName(i);
                start = param.start;
                end = param.end;
                condition = param.condition;
                update = param.update;

                if (Std.is(start, Int)) start = start.toString();
                else if (start != null && Std.is(start, Node)) start = start.build(builder, type);

                if (Std.is(end, Int)) end = end.toString();
                else if (end != null && Std.is(end, Node)) end = end.build(builder, type);

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

            var internalParam = { start: start, end: end, condition: condition };

            var startSnippet = internalParam.start;
            var endSnippet = internalParam.end;

            var declarationSnippet = '';
            var conditionalSnippet = '';
            var updateSnippet = '';

            if (update == null) {
                if (type == 'Int' || type == 'Uint') {
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

            var forSnippet = 'for (' + declarationSnippet + '; ' + conditionalSnippet + '; ' + updateSnippet + ')';

            builder.addFlowCode((i == 0 ? '\n' : '') + builder.tab + forSnippet + ' {\n\n').addFlowTab();
        }

        var stackSnippet = new ContextNode(stackNode, contextData).build(builder, 'Void');

        var returnsSnippet = properties.returnsNode != null ? properties.returnsNode.build(builder) : '';

        builder.removeFlowTab().addFlowCode('\n' + builder.tab + stackSnippet);

        for (i in 0...this.params.length - 1) {
            builder.addFlowCode((i == 0 ? '' : builder.tab) + '}\n\n').removeFlowTab();
        }

        builder.addFlowTab();

        return returnsSnippet;
    }
}

function loop(...params): ShaderNode {
    return new ShaderNode(new LoopNode(params));
}

function Continue(): ExpressionNode {
    return new ExpressionNode('continue');
}

function Break(): ExpressionNode {
    return new ExpressionNode('break');
}

ShaderNode.addNodeElement('loop', function(returns, ...params) {
    return new BypassNode(returns, loop(params));
});

Node.addNodeClass('LoopNode', LoopNode);