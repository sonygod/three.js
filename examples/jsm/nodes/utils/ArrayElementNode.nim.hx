import Node, { addNodeClass } from '../core/Node.js';

class ArrayElementNode extends Node {

	public var node:Node;
	public var indexNode:Node;

	public var isArrayElementNode:Bool = true;

	public function new( node:Node, indexNode:Node ) {

		super();

		this.node = node;
		this.indexNode = indexNode;

	}

	public function getNodeType( builder:Dynamic ) {

		return this.node.getNodeType( builder );

	}

	public function generate( builder:Dynamic ) {

		var nodeSnippet:String = this.node.build( builder );
		var indexSnippet:String = this.indexNode.build( builder, 'uint' );

		return "${nodeSnippet}[ ${indexSnippet} ]";

	}

}

addNodeClass( 'ArrayElementNode', ArrayElementNode );