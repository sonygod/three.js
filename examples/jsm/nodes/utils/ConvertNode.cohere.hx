import Node from '../core/Node.hx';

class ConvertNode extends Node {
	public var node:Node;
	public var convertTo:String;

	public function new(node:Node, convertTo:String) {
		super();
		this.node = node;
		this.convertTo = convertTo;
	}

	public function getNodeType(builder:Dynamic) : String {
		var requestType = node.getNodeType(builder);
		var convertTo = null;
		for (overloadingType in convertTo.split('|')) {
			if (convertTo == null || builder.getTypeLength(requestType) == builder.getTypeLength(overloadingType)) {
				convertTo = overloadingType;
			}
		}
		return convertTo;
	}

	public override function serialize(data:Dynamic) {
		super.serialize(data);
		data.convertTo = convertTo;
	}

	public override function deserialize(data:Dynamic) {
		super.deserialize(data);
		convertTo = data.convertTo;
	}

	public function generate(builder:Dynamic, output:Dynamic) : Dynamic {
		var node = this.node;
		var type = getNodeType(builder);
		var snippet = node.build(builder, type);
		return builder.format(snippet, type, output);
	}
}

class ConvertNode_Impl_ {
	public static function __init__() {
		Node.addNodeClass('ConvertNode', ConvertNode);
	}
}