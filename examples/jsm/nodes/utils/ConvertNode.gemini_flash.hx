import Node from '../core/Node';
import AddNodeClass from '../core/AddNodeClass';

class ConvertNode extends Node {

	public var node:Node;
	public var convertTo:String;

	public function new(node:Node, convertTo:String) {
		super();
		this.node = node;
		this.convertTo = convertTo;
	}

	public function getNodeType(builder:Dynamic):String {

		var requestType = this.node.getNodeType(builder);
		var convertTo:String = null;

		for (overloadType in this.convertTo.split('|')) {

			if (convertTo == null || builder.getTypeLength(requestType) == builder.getTypeLength(overloadType)) {

				convertTo = overloadType;

			}

		}

		return convertTo;
	}

	public function serialize(data:Dynamic) {
		super.serialize(data);
		data.convertTo = this.convertTo;
	}

	public function deserialize(data:Dynamic) {
		super.deserialize(data);
		this.convertTo = data.convertTo;
	}

	public function generate(builder:Dynamic, output:Dynamic):Dynamic {

		var node = this.node;
		var type = this.getNodeType(builder);

		var snippet = node.build(builder, type);

		return builder.format(snippet, type, output);
	}

}

AddNodeClass.addNodeClass('ConvertNode', ConvertNode);