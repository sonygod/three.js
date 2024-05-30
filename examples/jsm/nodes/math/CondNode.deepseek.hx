import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.PropertyNode;
import three.js.examples.jsm.nodes.core.ContextNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;

class CondNode extends Node {

	public function new(condNode, ifNode, elseNode = null) {
		super();
		this.condNode = condNode;
		this.ifNode = ifNode;
		this.elseNode = elseNode;
	}

	public function getNodeType(builder:Builder):String {
		var ifType = this.ifNode.getNodeType(builder);
		if (this.elseNode !== null) {
			var elseType = this.elseNode.getNodeType(builder);
			if (builder.getTypeLength(elseType) > builder.getTypeLength(ifType)) {
				return elseType;
			}
		}
		return ifType;
	}

	public function generate(builder:Builder, output:String):String {
		var type = this.getNodeType(builder);
		var context = {tempWrite: false};
		var nodeData = builder.getDataFromNode(this);
		if (nodeData.nodeProperty !== undefined) {
			return nodeData.nodeProperty;
		}
		var ifNode = this.ifNode;
		var elseNode = this.elseNode;
		var needsOutput = output !== 'void';
		var nodeProperty = needsOutput ? PropertyNode.property(type).build(builder) : '';
		nodeData.nodeProperty = nodeProperty;
		var nodeSnippet = ContextNode.context(this.condNode/*, context*/).build(builder, 'bool');
		builder.addFlowCode("\n" + builder.tab + "if (" + nodeSnippet + ") {\n\n").addFlowTab();
		var ifSnippet = ContextNode.context(ifNode, context).build(builder, type);
		if (ifSnippet) {
			if (needsOutput) {
				ifSnippet = nodeProperty + ' = ' + ifSnippet + ';';
			} else {
				ifSnippet = 'return ' + ifSnippet + ';';
			}
		}
		builder.removeFlowTab().addFlowCode(builder.tab + "\t" + ifSnippet + "\n\n" + builder.tab + "}");
		if (elseNode !== null) {
			builder.addFlowCode(" else {\n\n").addFlowTab();
			var elseSnippet = ContextNode.context(elseNode, context).build(builder, type);
			if (elseSnippet) {
				if (needsOutput) {
					elseSnippet = nodeProperty + ' = ' + elseSnippet + ';';
				} else {
					elseSnippet = 'return ' + elseSnippet + ';';
				}
			}
			builder.removeFlowTab().addFlowCode(builder.tab + "\t" + elseSnippet + "\n\n" + builder.tab + "}\n\n");
		} else {
			builder.addFlowCode("\n\n");
		}
		return builder.format(nodeProperty, type, output);
	}
}

static function cond(condNode, ifNode, elseNode = null):CondNode {
	return new CondNode(condNode, ifNode, elseNode);
}

ShaderNode.addNodeElement('cond', cond);
Node.addNodeClass('CondNode', CondNode);