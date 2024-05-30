import TempNode from '../core/TempNode.hx';
import { addNodeClass } from '../core/Node.hx';
import {
	addNodeElement,
	nodeProxy,
	Vec4,
	Mat2,
	Mat4,
} from '../shadernode/ShaderNode.hx';
import { Cos, Sin } from '../math/MathNode.hx';

class RotateNode extends TempNode {

	public function new( positionNode:TempNode, rotationNode:TempNode ) {

		super();

		this.positionNode = positionNode;
		this.rotationNode = rotationNode;

	}

	public function getNodeType( builder ):String {

		return this.positionNode.getNodeType( builder );

	}

	public function setup( builder ):Dynamic {

		var rotationNode = this.rotationNode;
		var positionNode = this.positionNode;

		var nodeType = this.getNodeType( builder );

		if ( nodeType == 'vec2' ) {

			var cosAngle = rotationNode.cos();
			var sinAngle = rotationNode.sin();

			var rotationMatrix = Mat2.fromColumns(
				Vec4.fromArray( [ cosAngle, sinAngle ] ),
				Vec4.fromArray( [ sinAngle.negate(), cosAngle ] )
			);

			return rotationMatrix.mul( positionNode );

		} else {

			var rotation = rotationNode;
			var rotationXMatrix = Mat4.fromRows(
				Vec4.fromArray( [ 1.0, 0.0, 0.0, 0.0 ] ),
				Vec4.fromArray( [ 0.0, Cos.fromAngle( rotation.x ), Sin.fromAngle( rotation.x ).negate(), 0.0 ] ),
				Vec4.fromArray( [ 0.0, Sin.fromAngle( rotation.x ), Cos.fromAngle( rotation.x ), 0.0 ] ),
				Vec4.fromArray( [ 0.0, 0.0, 0.0, 1.0 ] )
			);
			var rotationYMatrix = Mat4.fromRows(
				Vec4.fromArray( [ Cos.fromAngle( rotation.y ), 0.0, Sin.fromAngle( rotation.y ), 0.0 ] ),
				Vec4.fromArray( [ 0.0, 1.0, 0.0, 0.0 ] ),
				Vec4.fromArray( [ Sin.fromAngle( rotation.y ).negate(), 0.0, Cos.fromAngle( rotation.y ), 0.0 ] ),
				Vec4.fromArray( [ 0.0, 0.0, 0.0, 1.0 ] )
			);
			var rotationZMatrix = Mat4.fromRows(
				Vec4.fromArray( [ Cos.fromAngle( rotation.z ), Sin.fromAngle( rotation.z ).negate(), 0.0, 0.0 ] ),
				Vec4.fromArray( [ Sin.fromAngle( rotation.z ), Cos.fromAngle( rotation.z ), 0.0, 0.0 ] ),
				Vec4.fromArray( [ 0.0, 0.0, 1.0, 0.0 ] ),
				Vec4.fromArray( [ 0.0, 0.0, 0.0, 1.0 ] )
			);

			return rotationXMatrix.mul( rotationYMatrix ).mul( rotationZMatrix ).mul( Vec4.fromArray( [ positionNode, 1.0 ] ) ).xyz;

		}

	}

}

@:export( default )
var RotateNode_ = RotateNode;

@:export( rotate )
var rotate = nodeProxy( RotateNode );

addNodeElement( 'rotate', rotate );

addNodeClass( 'RotateNode', RotateNode );