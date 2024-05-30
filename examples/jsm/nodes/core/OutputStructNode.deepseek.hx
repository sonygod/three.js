import Node;
import StructTypeNode;
import ShaderNode;

class OutputStructNode extends Node {

	public var members:Array<Dynamic>;
	public var isOutputStructNode:Bool;

	public function new(members:Array<Dynamic>) {
		super();
		this.members = members;
		this.isOutputStructNode = true;
	}

	public function setup(builder:Dynamic):Void {
		super.setup(builder);
		var types:Array<Dynamic> = [];
		for (member in this.members) {
			types.push(member.getNodeType(builder));
		}
		this.nodeType = builder.getStructTypeFromNode(new StructTypeNode(types)).name;
	}

	public function generate(builder:Dynamic, output:Dynamic):String {
		var nodeVar = builder.getVarFromNode(this);
		nodeVar.isOutputStructVar = true;
		var propertyName = builder.getPropertyName(nodeVar);
		var structPrefix = propertyName != '' ? propertyName + '.' : '';
		var i = 0;
		for (member in this.members) {
			var snippet = member.build(builder, output);
			builder.addLineFlowCode(structPrefix + 'm' + i + ' = ' + snippet);
			i++;
		}
		return propertyName;
	}

}

class OutputStruct {
	public static function new(members:Array<Dynamic>):OutputStructNode {
		return new OutputStructNode(members);
	}
}

ShaderNode.addNodeClass('OutputStructNode', OutputStructNode);