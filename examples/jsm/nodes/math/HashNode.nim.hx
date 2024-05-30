import Node, { addNodeClass } from '../core/Node.js';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';

class HashNode extends Node {

	public var seedNode:Node;

	public function new(seedNode:Node) {

		super();

		this.seedNode = seedNode;

	}

	public function setup( /*builder*/ ) {

		// Taken from https://www.shadertoy.com/view/XlGcRh, originally from pcg-random.org

		var state = this.seedNode.toUint().mul( 747796405 ).add( 2891336453 );
		var word = state.shiftRight( state.shiftRight( 28 ).add( 4 ) ).bitXor( state ).mul( 277803737 );
		var result = word.shiftRight( 22 ).bitXor( word );

		return result.toFloat().mul( 1 / Math.pow( 2, 32 ) ); // Convert to range [0, 1)

	}

}

export default HashNode;

export const hash = nodeProxy( HashNode );

addNodeElement( 'hash', hash );

addNodeClass( 'HashNode', HashNode );