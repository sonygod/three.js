import InputNode from './InputNode.js';
import { addNodeClass } from './Node.js';

class ConstNode extends InputNode {

	public var isConstNode:Bool = true;

	public function new(value:Dynamic, nodeType:Null<Dynamic>) {
		super(value, nodeType);
	}

	public function generateConst(builder:Dynamic):Dynamic {
		return builder.generateConst(this.getNodeType(builder), this.value);
	}

	public function generate(builder:Dynamic, output:Dynamic):Dynamic {
		var type = this.getNodeType(builder);
		return builder.format(this.generateConst(builder), type, output);
	}

}

addNodeClass('ConstNode', ConstNode);