import Node, { addNodeClass } from '../core/Node.js';
import { expression } from '../code/ExpressionNode.js';
import { bypass } from '../core/BypassNode.js';
import { context } from '../core/ContextNode.js';
import { addNodeElement, nodeObject, nodeArray } from '../shadernode/ShaderNode.js';

class LoopNode extends Node {

	public var params:Array<Dynamic>;

	public function new(params:Array<Dynamic> = []) {

		super();

		this.params = params;

	}

	public function getVarName(index:Int):String {

		return String.fromCharCode( 'i'.charCodeAt() + index );

	}

	public function getProperties(builder:Dynamic):Dynamic {

		var properties = builder.getNodeProperties(this);

		if (properties.stackNode !== null) return properties;

		//

		var inputs:Dynamic = new Dynamic();

		for (i in 0...this.params.length - 1) {

			var param = this.params[i];

			var name:String = (param.isNode !== true && param.name) || this.getVarName(i);
			var type:String = (param.isNode !== true && param.type) || 'int';

			inputs[name] = expression(name, type);

		}

		properties.returnsNode = this.params[this.params.length - 1](inputs, builder.addStack(), builder);
		properties.stackNode = builder.removeStack();

		return properties;

	}

	public function getNodeType(builder:Dynamic):String {

		var { returnsNode } = this.getProperties(builder);

		return returnsNode ? returnsNode.getNodeType(builder) : 'void';

	}

	public function setup(builder:Dynamic) {

		// setup properties

		this.getProperties(builder);

	}

	public function generate(builder:Dynamic):String {

		var properties = this.getProperties(builder);

		var contextData:Dynamic = { tempWrite: false };

		var params = this.params;
		var stackNode = properties.stackNode;

		for (i in 0...params.length - 1) {

			var param = params[i];

			var start:String = null, end:String = null, name:String = null, type:String = null, condition:String = null, update:String = null;

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

				if (Type.typeof(start) == TInt) start = start.toString();
				else if (start && start.isNode) start = start.build(builder, type);

				if (Type.typeof(end) == TInt) end = end.toString();
				else if (end && end.isNode) end = end.build(builder, type);

				if (start !== null && end == null) {

					start = start + ' - 1';
					end = '0';
					condition = '>=';

				} else if (end !== null && start == null) {

					start = '0';
					condition = '<';

				}

				if (condition == null) {

					if (Std.int(start) > Std.int(end)) {

						condition = '>=';

					} else {

						condition = '<';

					}

				}

			}

			var internalParam:Dynamic = { start, end, condition };

			//

			var startSnippet = internalParam.start;
			var endSnippet = internalParam.end;

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

			var forSnippet = `for ( ${ declarationSnippet }; ${ conditionalSnippet }; ${ updateSnippet } )`;

			builder.addFlowCode((i == 0 ? '\n' : '') + builder.tab + forSnippet + ' {\n\n').addFlowTab();

		}

		var stackSnippet = context(stackNode, contextData).build(builder, 'void');

		var returnsSnippet = properties.returnsNode ? properties.returnsNode.build(builder) : '';

		builder.removeFlowTab().addFlowCode('\n' + builder.tab + stackSnippet);

		for (i in 0...this.params.length - 1) {

			builder.addFlowCode((i == 0 ? '' : builder.tab) + '}\n\n').removeFlowTab();

		}

		builder.addFlowTab();

		return returnsSnippet;

	}

}

export default LoopNode;

export function loop(...params):Dynamic {

	return nodeObject(new LoopNode(nodeArray(params, 'int'))).append();

}

export function Continue():Dynamic {

	return expression('continue').append();

}

export function Break():Dynamic {

	return expression('break').append();

}

addNodeElement('loop', (returns:Dynamic, ...params:Array<Dynamic>) => bypass(returns, loop(...params)));

addNodeClass('LoopNode', LoopNode);