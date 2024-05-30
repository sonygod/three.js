import Node from '../core/Node.hx';

class ArrayElementNode extends Node { // @TODO: If extending from TempNode it breaks webgpu_compute

	public function new( node, indexNode ) {

		super();

		this.node = node;
		this.indexNode = indexNode;

	}

	public function getNodeType( builder : Builder ) : Integer {

		return this.node.getNodeType( builder );

	}

	public function generate( builder : Builder ) : String {

		var nodeSnippet = this.node.build( builder );
		var indexSnippet = this.indexNode.build( builder, 'uint' );

		return '${nodeSnippet}[ ${indexSnippet} ]';

	}

}

class NodeClass {
	public static function add( name : String, node : Node ) {
		// ...
	}
}

NodeClass.add( 'ArrayElementNode', ArrayElementNode );