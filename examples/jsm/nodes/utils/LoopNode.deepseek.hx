import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.code.ExpressionNode;
import three.js.examples.jsm.nodes.core.BypassNode;
import three.js.examples.jsm.nodes.core.ContextNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class LoopNode extends Node {

	public function new(params:Array<Dynamic> = []) {
		super();
		this.params = params;
	}

	public function getVarName(index:Int):String {
		return String.fromCharCode('i'.charCodeAt() + index);
	}

	public function getProperties(builder:ShaderNode.Builder):Dynamic {
		var properties = builder.getNodeProperties(this);
		if (properties.stackNode !== undefined) return properties;

		var inputs = {};
		for (i in 0...this.params.length - 1) {
			var param = this.params[i];
			var name = (param.isNode !== true && param.name) || this.getVarName(i);
			var type = (param.isNode !== true && param.type) || 'int';
			inputs[name] = ExpressionNode.expression(name, type);
		}

		properties.returnsNode = this.params[this.params.length - 1](inputs, builder.addStack(), builder);
		properties.stackNode = builder.removeStack();

		return properties;
	}

	public function getNodeType(builder:ShaderNode.Builder):String {
		var properties = this.getProperties(builder);
		return properties.returnsNode ? properties.returnsNode.getNodeType(builder) : 'void';
	}

	public function setup(builder:ShaderNode.Builder):Void {
		this.getProperties(builder);
	}

	public function generate(builder:ShaderNode.Builder):String {
		var properties = this.getProperties(builder);
		var contextData = { tempWrite: false };
		var params = this.params;
		var stackNode = properties.stackNode;

		for (i in 0...params.length - 1) {
			var param = params[i];
			var start = null, end = null, name = null, type = null, condition = null, update = null;

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

				if (typeof start === 'number') start = start.toString();
				else if (start && start.isNode) start = start.build(builder, type);

				if (typeof end === 'number') end = end.toString();
				else if (end && end.isNode) end = end.build(builder, type);

				if (start !== undefined && end === undefined) {
					start = start + ' - 1';
					end = '0';
					condition = '>=';
				} else if (end !== undefined && start === undefined) {
					start = '0';
					condition = '<';
				}

				if (condition === undefined) {
					if (Number(start) > Number(end)) {
						condition = '>=';
					} else {
						condition = '<';
					}
				}
			}

			var internalParam = { start:start, end:end, condition:condition };
			var startSnippet = internalParam.start;
			var endSnippet = internalParam.end;
			var declarationSnippet = '';
			var conditionalSnippet = '';
			var updateSnippet = '';

			if (!update) {
				if (type == 'int' || type == 'uint') {
					if (condition.includes('<')) update = '++';
					else update = '--';
				} else {
					if (condition.includes('<')) update = '+= 1.';
					else update = '-= 1.';
				}
			}

			declarationSnippet += builder.getVar(type, name) + ' = ' + startSnippet;
			conditionalSnippet += name + ' ' + condition + ' ' + endSnippet;
			updateSnippet += name + ' ' + update;
			var forSnippet = 'for (' + declarationSnippet + '; ' + conditionalSnippet + '; ' + updateSnippet + ')';

			builder.addFlowCode((i == 0 ? '\n' : '') + builder.tab + forSnippet + ' {\n\n').addFlowTab();
		}

		var stackSnippet = ContextNode.context(stackNode, contextData).build(builder, 'void');
		var returnsSnippet = properties.returnsNode ? properties.returnsNode.build(builder) : '';
		builder.removeFlowTab().addFlowCode('\n' + builder.tab + stackSnippet);

		for (i in 0...this.params.length - 1) {
			builder.addFlowCode((i == 0 ? '' : builder.tab) + '}\n\n').removeFlowTab();
		}

		builder.addFlowTab();

		return returnsSnippet;
	}
}

static function loop(params:Array<Dynamic>):ShaderNode {
	return ShaderNode.nodeObject(new LoopNode(ShaderNode.nodeArray(params, 'int'))).append();
}

static function Continue():ExpressionNode {
	return ExpressionNode.expression('continue').append();
}

static function Break():ExpressionNode {
	return ExpressionNode.expression('break').append();
}

ShaderNode.addNodeElement('loop', (returns:Dynamic, params:Array<Dynamic>) -> BypassNode.bypass(returns, loop(params)));

ShaderNode.addNodeClass('LoopNode', LoopNode);