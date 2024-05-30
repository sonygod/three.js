import three.js.examples.jsm.nodes.core.Node;
import three.js.examples.jsm.nodes.core.TempNode;
import three.js.examples.jsm.nodes.shadernode.ShaderNode;
import three.js.examples.jsm.nodes.core.constants.vectorComponents;

class AssignNode extends TempNode {

	var targetNode:Dynamic;
	var sourceNode:Dynamic;

	public function new(targetNode:Dynamic, sourceNode:Dynamic) {
		super();
		this.targetNode = targetNode;
		this.sourceNode = sourceNode;
	}

	public function hasDependencies():Bool {
		return false;
	}

	public function getNodeType(builder:Dynamic, output:Dynamic):String {
		return (output !== 'void') ? this.targetNode.getNodeType(builder) : 'void';
	}

	public function needsSplitAssign(builder:Dynamic):Bool {
		var targetNode = this.targetNode;
		if (builder.isAvailable('swizzleAssign') === false && targetNode.isSplitNode && targetNode.components.length > 1) {
			var targetLength = builder.getTypeLength(targetNode.node.getNodeType(builder));
			var assignDiferentVector = vectorComponents.join('').slice(0, targetLength) !== targetNode.components;
			return assignDiferentVector;
		}
		return false;
	}

	public function generate(builder:Dynamic, output:Dynamic):String {
		var targetNode = this.targetNode;
		var sourceNode = this.sourceNode;
		var needsSplitAssign = this.needsSplitAssign(builder);
		var targetType = targetNode.getNodeType(builder);
		var target = targetNode.context({assign: true}).build(builder);
		var source = sourceNode.build(builder, targetType);
		var sourceType = sourceNode.getNodeType(builder);
		var nodeData = builder.getDataFromNode(this);
		var snippet:String;
		if (nodeData.initialized === true) {
			if (output !== 'void') {
				snippet = target;
			}
		} else if (needsSplitAssign) {
			var sourceVar = builder.getVarFromNode(this, null, targetType);
			var sourceProperty = builder.getPropertyName(sourceVar);
			builder.addLineFlowCode(`${sourceProperty} = ${source}`);
			var targetRoot = targetNode.node.context({assign: true}).build(builder);
			for (i in 0...targetNode.components.length) {
				var component = targetNode.components[i];
				builder.addLineFlowCode(`${targetRoot}.${component} = ${sourceProperty}[${i}]`);
			}
			if (output !== 'void') {
				snippet = target;
			}
		} else {
			snippet = `${target} = ${source}`;
			if (output === 'void' || sourceType === 'void') {
				builder.addLineFlowCode(snippet);
				if (output !== 'void') {
					snippet = target;
				}
			}
		}
		nodeData.initialized = true;
		return builder.format(snippet, targetType, output);
	}

	static function assign(targetNode:Dynamic, sourceNode:Dynamic):AssignNode {
		return new AssignNode(targetNode, sourceNode);
	}
}

Node.addNodeClass('AssignNode', AssignNode);
ShaderNode.addNodeElement('assign', AssignNode.assign);