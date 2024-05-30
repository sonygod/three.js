import Node from './Node.hx';

class StructTypeNode extends Node {
	public var types:Dynamic;
	public var isStructTypeNode:Bool = true;

	public function new(types:Dynamic) {
		super();
		this.types = types;
	}

	public function getMemberTypes():Dynamic {
		return this.types;
	}
}

@:struct
class StructTypeNodeData {
	public var name:String;
	public var value:StructTypeNode;
}

class StructTypeNodeLibrary {
	public static var nodeClasses:Array<StructTypeNodeData>;

	public static function addNodeClass(name:String, node:StructTypeNode) {
		StructTypeNodeLibrary.nodeClasses.push({ name: name, value: node });
	}
}

StructTypeNodeLibrary.addNodeClass('StructTypeNode', StructTypeNode);

class Export {
	public static var default:StructTypeNode = StructTypeNode;
}