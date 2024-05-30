import Node, { addNodeClass } from '../core/Node.js';
import { nodeImmutable, float } from '../shadernode/ShaderNode.js';
import { BackSide, WebGLCoordinateSystem } from 'three';

class FrontFacingNode extends Node {

	public function new() {

		super('bool');

		this.isFrontFacingNode = true;

	}

	public function generate( builder ) {

		var { renderer, material } = builder;

		if (renderer.coordinateSystem == WebGLCoordinateSystem) {

			if (material.side == BackSide) {

				return 'false';

			}

		}

		return builder.getFrontFacing();

	}

}

export default FrontFacingNode;

export var frontFacing = nodeImmutable( FrontFacingNode );
export var faceDirection = float( frontFacing ).mul( 2.0 ).sub( 1.0 );

addNodeClass( 'FrontFacingNode', FrontFacingNode );