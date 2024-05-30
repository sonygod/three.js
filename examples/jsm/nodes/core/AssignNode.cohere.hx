import haxe.root.*;
import js.Browser.window;

import js.Node;
import js.TempNode;
import js.ShaderNode;
import js.constants;

class AssignNode extends TempNode {
	public var targetNode:TempNode;
	public var sourceNode:TempNode;

	public function new(targetNode:TempNode, sourceNode:TempNode) {
		super();
		this.targetNode = targetNode;
		this.sourceNode = sourceNode;
	}

	public function hasDependencies():Bool {
		return false;
	}

	public function getNodeType(builder:js.ShaderBuilder, output:String):String {
		return output != 'void' ? targetNode.getNodeType(builder) : 'void';
	}

	public function needsSplitAssign(builder:js.ShaderBuilder):Bool {
		if (!builder.isAvailable('swizzleAssign') && targetNode.isSplitNode && targetNode.components.length > 1) {
			let targetLength = builder.getTypeLength(targetNode.getNodeType(builder));
			let assignDiferentVector = false;
			for (c in vectorComponents) {
				if (targetLength == c.length) {
					assignDiferentVector = targetNode.components != c;
					break;
				}
			}
			return assignDiferentVector;
		}
		return false;
	}

	public function generate(builder:js.ShaderBuilder, output:String):String {
		let targetType = targetNode.getNodeType(builder);
		let target = targetNode.context({assign: true}).build(builder);
		let source = sourceNode.build(builder, targetType);
		let sourceType = sourceNode.getNodeType(builder);

		let nodeData = builder.getDataFromNode(this);
		let snippet:String;

		if (nodeData.initialized) {
			if (output != 'void') {
				snippet = target;
			}
		} else if (needsSplitAssign(builder)) {
			let sourceVar = builder.getVarFromNode(this, null, targetType);
			let sourceProperty = builder.getPropertyName(sourceVar);
			builder.addLineFlowCode(sourceProperty + ' = ' + source);
			let targetRoot = targetNode.node.context({assign: true}).build(builder);
			for (i in 0...targetNode.components.length) {
				let component = targetNode.components[i];
				builder.addLineFlowCode(targetRoot + '.' + component + ' = ' + sourceProperty + '[' + Std.string(i) + ']');
			}
			if (output != 'void') {
				snippet = target;
			}
		} else {
			snippet = target + ' = ' + source;
			if (output == 'void' || sourceType == 'void') {
				builder.addLineFlowCode(snippet);
				if (output != 'void') {
					snippet = target;
				}
			}
		}

		nodeData.initialized = true;
		return builder.format(snippet, targetType, output);
	}
}

class js_AssignNode {
	public static function main() {
		js.ShaderNode.addNodeClass('AssignNode', AssignNode);
		js.ShaderNode.addNodeElement('assign', js.ShaderNode.nodeProxy(AssignNode));
	}
}