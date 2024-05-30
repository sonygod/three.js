import InputNode from './InputNode.hx';
import Node from './Node.hx';

class ConstNode extends InputNode {

	public function new(value:Dynamic, nodeType:Dynamic = null) {
		super(value, nodeType);
		this.isConstNode = true;
	}

	public function generateConst(builder:Dynamic):Dynamic {
		return builder.generateConst(this.getNodeType(builder), this.value);
	}

	public function generate(builder:Dynamic, output:Dynamic):Dynamic {
		var type = this.getNodeType(builder);
		return builder.format(this.generateConst(builder), type, output);
	}

}

Node.addNodeClass('ConstNode', ConstNode);