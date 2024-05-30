import TempNode from '../core/TempNode.js';
import { uv } from '../accessors/UVNode.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, tslFn, nodeProxy } from '../shadernode/ShaderNode.js';

var checkerShaderNode = tslFn( ( inputs ) -> {

	var uv = inputs.uv.mul( 2.0 );

	var cx = uv.x.floor();
	var cy = uv.y.floor();
	var result = cx.add( cy ).mod( 2.0 );

	return result.sign();

} );

class CheckerNode extends TempNode {

	public var uvNode:Dynamic;

	public function new( uvNode:Dynamic = uv() ) {

		super('float');

		this.uvNode = uvNode;

	}

	public function setup():Dynamic {

		return checkerShaderNode( { uv: this.uvNode } );

	}

}

export default CheckerNode;

export var checker = nodeProxy( CheckerNode );

addNodeElement( 'checker', checker );

addNodeClass( 'CheckerNode', CheckerNode );