import Node from "../core/Node";
import ExpressionNode from "../code/ExpressionNode";
import BypassNode from "../core/BypassNode";
import ContextNode from "../core/ContextNode";
import ShaderNode from "../shadernode/ShaderNode";

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
		if (properties.stackNode != null) return properties;
		var inputs:Dynamic = {};
		for (i in 0...this.params.length - 1) {
			var param = this.params[i];
			var name:String = (param.isNode == false && param.name != null) ? param.name : this.getVarName(i);
			var type:String = (param.isNode == false && param.type != null) ? param.type : 'int';
			inputs[name] = ExpressionNode.expression(name, type);
		}
		properties.returnsNode = this.params[this.params.length - 1](inputs, builder.addStack(), builder);
		properties.stackNode = builder.removeStack();
		return properties;
	}

	public function getNodeType(builder:Dynamic):String {
		var properties = this.getProperties(builder);
		return properties.returnsNode != null ? properties.returnsNode.getNodeType(builder) : 'void';
	}

	public function setup(builder:Dynamic):Void {
		this.getProperties(builder);
	}

	public function generate(builder:Dynamic):String {
		var properties = this.getProperties(builder);
		var contextData:Dynamic = {tempWrite: false};
		var params = this.params;
		var stackNode = properties.stackNode;
		for (i in 0...params.length - 1) {
			var param = params[i];
			var start:Dynamic = null;
			var end:Dynamic = null;
			var name:String = null;
			var type:String = null;
			var condition:String = null;
			var update:Dynamic = null;
			if (param.isNode) {
				type = 'int';
				name = this.getVarName(i);
				start = '0';
				end = param.build(builder, type);
				condition = '<';
			} else {
				type = param.type != null ? param.type : 'int';
				name = param.name != null ? param.name : this.getVarName(i);
				start = param.start;
				end = param.end;
				condition = param.condition;
				update = param.update;
				if (Std.is(start, Int)) start = Std.string(start);
				else if (start != null && start.isNode) start = start.build(builder, type);
				if (Std.is(end, Int)) end = Std.string(end);
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
					if (Std.parseFloat(start) > Std.parseFloat(end)) {
						condition = '>=';
					} else {
						condition = '<';
					}
				}
			}
			var internalParam:Dynamic = {start, end, condition};
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
		var stackSnippet:String = ContextNode.context(stackNode, contextData).build(builder, 'void');
		var returnsSnippet:String = properties.returnsNode != null ? properties.returnsNode.build(builder) : '';
		builder.removeFlowTab().addFlowCode('\n' + builder.tab + stackSnippet);
		for (i in 0...this.params.length - 1) {
			builder.addFlowCode((i == 0 ? '' : builder.tab) + '}\n\n').removeFlowTab();
		}
		builder.addFlowTab();
		return returnsSnippet;
	}

}

export var loop = function(...params:Dynamic):Dynamic {
	return ShaderNode.nodeObject(new LoopNode(ShaderNode.nodeArray(params, 'int'))).append();
};

export var Continue = function():Dynamic {
	return ExpressionNode.expression('continue').append();
};

export var Break = function():Dynamic {
	return ExpressionNode.expression('break').append();
};

ShaderNode.addNodeElement('loop', function(returns:Dynamic, ...params:Dynamic):Dynamic {
	return BypassNode.bypass(returns, loop(...params));
});

ShaderNode.addNodeClass('LoopNode', LoopNode);