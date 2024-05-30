import Node, { addNodeClass } from './Node.hx';
import StructTypeNode from './StructTypeNode.hx';

@:isNode
class OutputStructNode extends Node {
	public var members:Array<Node>;
	public var isOutputStructNode:Bool = true;

	public function new(...members:Array<Node>) {
		super();
		this.members = members;
	}

	override function setup(builder:Builder) {
		super.setup(builder);
		var types = [];
		for (member in members) {
			types.push(member.getNodeType(builder));
		}
		this.nodeType = builder.getStructTypeFromNode(new StructTypeNode(types)).name;
	}

	override function generate(builder:Builder, output:Output) -> String {
		var nodeVar = builder.getVarFromNode(this);
		nodeVar.isOutputStructVar = true;
		var propertyName = builder.getPropertyName(nodeVar);
		var structPrefix = if (propertyName != '') propertyName + '.';
		for (i in 0...members.length) {
			var snippet = members[i].build(builder, output);
			builder.addLineFlowCode(Code.ExprPos(structPrefix + 'm' + i, '=', snippet));
		}
		return propertyName;
	}
}

@:nodeProxy(OutputStructNode)
var outputStruct:Void->OutputStructNode;

addNodeClass('OutputStructNode', OutputStructNode);

class Code {
	public static function ExprPos(name:String, op:String, value:Expr) -> ExprPos {
		return { name: name, op: op, value: value };
	}
}

class Expr {}

class ExprPos extends Expr {
	public var name:String;
	public var op:String;
	public var value:Expr;
}