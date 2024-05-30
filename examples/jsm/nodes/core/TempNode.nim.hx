import Node, { addNodeClass } from './Node.js';

class TempNode extends Node {

	public var isTempNode:Bool = true;

	public function new(type:String) {
		super(type);
	}

	public function hasDependencies(builder:Dynamic):Bool {
		return builder.getDataFromNode(this).usageCount > 1;
	}

	public function build(builder:Dynamic, output:String):String {
		var buildStage:String = builder.getBuildStage();

		if (buildStage == 'generate') {
			var type:String = builder.getVectorType(this.getNodeType(builder, output));
			var nodeData:Dynamic = builder.getDataFromNode(this);

			if (builder.context.tempRead != false && nodeData.propertyName != null) {
				return builder.format(nodeData.propertyName, type, output);
			} else if (builder.context.tempWrite != false && type != 'void' && output != 'void' && this.hasDependencies(builder)) {
				var snippet:String = super.build(builder, type);

				var nodeVar:Dynamic = builder.getVarFromNode(this, null, type);
				var propertyName:String = builder.getPropertyName(nodeVar);

				builder.addLineFlowCode("${propertyName} = ${snippet}");

				nodeData.snippet = snippet;
				nodeData.propertyName = propertyName;

				return builder.format(nodeData.propertyName, type, output);
			}
		}

		return super.build(builder, output);
	}

}

export default TempNode;

addNodeClass('TempNode', TempNode);