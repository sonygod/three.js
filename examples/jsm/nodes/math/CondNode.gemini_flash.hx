import Node from '../core/Node';
import {property} from '../core/PropertyNode';
import {context as contextNode} from '../core/ContextNode';
import {addNodeElement, nodeProxy} from '../shadernode/ShaderNode';

class CondNode extends Node {

	public condNode:Node;
	public ifNode:Node;
	public elseNode:Node;

	public function new(condNode:Node, ifNode:Node, elseNode:Node = null) {
		super();
		this.condNode = condNode;
		this.ifNode = ifNode;
		this.elseNode = elseNode;
	}

	public function getNodeType(builder:Dynamic):Dynamic {
		var ifType = this.ifNode.getNodeType(builder);
		if (this.elseNode != null) {
			var elseType = this.elseNode.getNodeType(builder);
			if (builder.getTypeLength(elseType) > builder.getTypeLength(ifType)) {
				return elseType;
			}
		}
		return ifType;
	}

	public function generate(builder:Dynamic, output:String):String {
		var type = this.getNodeType(builder);
		var context = {tempWrite: false};
		var nodeData = builder.getDataFromNode(this);

		if (nodeData.nodeProperty != null) {
			return nodeData.nodeProperty;
		}

		var {ifNode, elseNode} = this;
		var needsOutput = output != "void";
		var nodeProperty = needsOutput ? property(type).build(builder) : "";
		nodeData.nodeProperty = nodeProperty;

		var nodeSnippet = contextNode(this.condNode/*, context*/).build(builder, "bool");

		builder.addFlowCode(`\n${builder.tab}if (${nodeSnippet}) {\n\n`).addFlowTab();

		var ifSnippet = contextNode(ifNode, context).build(builder, type);

		if (ifSnippet != null) {
			if (needsOutput) {
				ifSnippet = nodeProperty + " = " + ifSnippet + ";";
			} else {
				ifSnippet = "return " + ifSnippet + ";";
			}
		}

		builder.removeFlowTab().addFlowCode(builder.tab + "\t" + ifSnippet + "\n\n" + builder.tab + "}");

		if (elseNode != null) {
			builder.addFlowCode(" else {\n\n").addFlowTab();

			var elseSnippet = contextNode(elseNode, context).build(builder, type);

			if (elseSnippet != null) {
				if (needsOutput) {
					elseSnippet = nodeProperty + " = " + elseSnippet + ";";
				} else {
					elseSnippet = "return " + elseSnippet + ";";
				}
			}

			builder.removeFlowTab().addFlowCode(builder.tab + "\t" + elseSnippet + "\n\n" + builder.tab + "}\n\n");
		} else {
			builder.addFlowCode("\n\n");
		}

		return builder.format(nodeProperty, type, output);
	}

}

export default CondNode;

export var cond = nodeProxy(CondNode);

addNodeElement("cond", cond);

addNodeClass("CondNode", CondNode);