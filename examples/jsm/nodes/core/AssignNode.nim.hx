import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.shadernode.ShaderNode;
import three.js.examples.jsm.core.constants;

class AssignNode extends TempNode {

	public var targetNode:Node;
	public var sourceNode:Node;

	public function new(targetNode:Node, sourceNode:Node) {
		super();
		this.targetNode = targetNode;
		this.sourceNode = sourceNode;
	}

	public function hasDependencies():Bool {
		return false;
	}

	public function getNodeType(builder:ShaderNode, output:String):String {
		return output !== 'void' ? this.targetNode.getNodeType(builder) : 'void';
	}

	public function needsSplitAssign(builder:ShaderNode):Bool {
		if (builder.isAvailable('swizzleAssign') === false && this.targetNode.isSplitNode && this.targetNode.components.length > 1) {
			const targetLength = builder.getTypeLength(this.targetNode.node.getNodeType(builder));
			const assignDiferentVector = constants.vectorComponents.join('').slice(0, targetLength) !== this.targetNode.components;
			return assignDiferentVector;
		}
		return false;
	}

	public function generate(builder:ShaderNode, output:String):String {
		const needsSplitAssign = this.needsSplitAssign(builder);
		const targetType = this.targetNode.getNodeType(builder);
		const target = this.targetNode.context({assign: true}).build(builder);
		const source = this.sourceNode.build(builder, targetType);
		const sourceType = this.sourceNode.getNodeType(builder);
		var snippet:String;
		if (this.nodeData.initialized === true) {
			if (output !== 'void') {
				snippet = target;
			}
		} else if (needsSplitAssign) {
			const sourceVar = builder.getVarFromNode(this, null, targetType);
			const sourceProperty = builder.getPropertyName(sourceVar);
			builder.addLineFlowCode("${sourceProperty} = ${source}");
			const targetRoot = this.targetNode.node.context({assign: true}).build(builder);
			for (i in 0...this.targetNode.components.length) {
				const component = this.targetNode.components[i];
				builder.addLineFlowCode("${targetRoot}.${component} = ${sourceProperty}[${i}]");
			}
			if (output !== 'void') {
				snippet = target;
			}
		} else {
			snippet = "${target} = ${source}";
			if (output === 'void' || sourceType === 'void') {
				builder.addLineFlowCode(snippet);
				if (output !== 'void') {
					snippet = target;
				}
			}
		}
		this.nodeData.initialized = true;
		return builder.format(snippet, targetType, output);
	}

}

Node.addNodeClass('AssignNode', AssignNode);
ShaderNode.addNodeElement('assign', AssignNode);