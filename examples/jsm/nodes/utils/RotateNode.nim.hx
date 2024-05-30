import TempNode from '../core/TempNode.js';
import { addNodeClass } from '../core/Node.js';
import {
	addNodeElement,
	nodeProxy,
	vec4,
	mat2,
	mat4,
} from '../shadernode/ShaderNode.js';
import { cos, sin } from '../math/MathNode.js';

class RotateNode extends TempNode {

	public var positionNode:Dynamic;
	public var rotationNode:Dynamic;

	public function new( positionNode:Dynamic, rotationNode:Dynamic ) {

		super();

		this.positionNode = positionNode;
		this.rotationNode = rotationNode;

	}

	public function getNodeType( builder:Dynamic ):Dynamic {

		return this.positionNode.getNodeType( builder );

	}

	public function setup( builder:Dynamic ):Dynamic {

		var rotationNode:Dynamic = this.rotationNode;
		var positionNode:Dynamic = this.positionNode;

		var nodeType:Dynamic = this.getNodeType( builder );

		if ( nodeType == 'vec2' ) {

			var cosAngle:Dynamic = rotationNode.cos();
			var sinAngle:Dynamic = rotationNode.sin();

			var rotationMatrix:Dynamic = mat2(
				cosAngle, sinAngle,
				sinAngle.negate(), cosAngle
			);

			return rotationMatrix.mul( positionNode );

		} else {

			var rotation:Dynamic = rotationNode;
			var rotationXMatrix:Dynamic = mat4( vec4( 1.0, 0.0, 0.0, 0.0 ), vec4( 0.0, cos( rotation.x ), sin( rotation.x ).negate(), 0.0 ), vec4( 0.0, sin( rotation.x ), cos( rotation.x ), 0.0 ), vec4( 0.0, 0.0, 0.0, 1.0 ) );
			var rotationYMatrix:Dynamic = mat4( vec4( cos( rotation.y ), 0.0, sin( rotation.y ), 0.0 ), vec4( 0.0, 1.0, 0.0, 0.0 ), vec4( sin( rotation.y ).negate(), 0.0, cos( rotation.y ), 0.0 ), vec4( 0.0, 0.0, 0.0, 1.0 ) );
			var rotationZMatrix:Dynamic = mat4( vec4( cos( rotation.z ), sin( rotation.z ).negate(), 0.0, 0.0 ), vec4( sin( rotation.z ), cos( rotation.z ), 0.0, 0.0 ), vec4( 0.0, 0.0, 1.0, 0.0 ), vec4( 0.0, 0.0, 0.0, 1.0 ) );

			return rotationXMatrix.mul( rotationYMatrix ).mul( rotationZMatrix ).mul( vec4( positionNode, 1.0 ) ).xyz;

		}

	}

}

export default RotateNode;

export var rotate:Dynamic = nodeProxy( RotateNode );

addNodeElement( 'rotate', rotate );

addNodeClass( 'RotateNode', RotateNode );