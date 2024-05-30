import Node, { addNodeClass } from '../core/Node.js';
import { float, addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';

class RemapNode extends Node {

	public var node: Node;
	public var inLowNode: Node;
	public var inHighNode: Node;
	public var outLowNode: Node;
	public var outHighNode: Node;

	public var doClamp: Bool;

	public function new( node: Node, inLowNode: Node, inHighNode: Node, outLowNode: Node = float( 0 ), outHighNode: Node = float( 1 ) ) {

		super();

		this.node = node;
		this.inLowNode = inLowNode;
		this.inHighNode = inHighNode;
		this.outLowNode = outLowNode;
		this.outHighNode = outHighNode;

		this.doClamp = true;

	}

	public function setup(): Node {

		let t = this.node.sub( this.inLowNode ).div( this.inHighNode.sub( this.inLowNode ) );

		if ( this.doClamp === true ) t = t.clamp();

		return t.mul( this.outHighNode.sub( this.outLowNode ) ).add( this.outLowNode );

	}

}

export default RemapNode;

export const remap = nodeProxy( RemapNode, null, null, { doClamp: false } );
export const remapClamp = nodeProxy( RemapNode );

addNodeElement( 'remap', remap );
addNodeElement( 'remapClamp', remapClamp );

addNodeClass( 'RemapNode', RemapNode );