import InputNode from './InputNode.hx';
import { addNodeClass } from './Node.hx';

class ConstNode extends InputNode {
	public isConstNode:Bool;
	public function new( value:Dynamic, nodeType:String ) {
		super( value, nodeType );
		this.isConstNode = true;
	}

	public function generateConst( builder:Dynamic ):Dynamic {
		return builder.generateConst( this.getNodeType( builder ), this.value );
	}

	public function generate( builder:Dynamic, output:Dynamic ):Dynamic {
		var type = this.getNodeType( builder );
		return builder.format( this.generateConst( builder ), type, output );
	}

}

@:build(addNodeClass('ConstNode',ConstNode))
class Export {}