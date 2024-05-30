import Node, { addNodeClass } from '../core/Node.js';
import { attribute } from '../core/AttributeNode.js';
import { varying } from '../core/VaryingNode.js';
import { normalize } from '../math/MathNode.js';
import { modelWorldMatrix, modelViewMatrix } from './ModelNode.js';
import { nodeImmutable } from '../shadernode/ShaderNode.js';

class PositionNode extends Node {

	public static var GEOMETRY:String = 'geometry';
	public static var LOCAL:String = 'local';
	public static var WORLD:String = 'world';
	public static var WORLD_DIRECTION:String = 'worldDirection';
	public static var VIEW:String = 'view';
	public static var VIEW_DIRECTION:String = 'viewDirection';

	public var scope:String;

	public function new( scope:String = LOCAL ) {

		super('vec3');

		this.scope = scope;

	}

	public function isGlobal():Bool {

		return true;

	}

	public function getHash( /*builder*/ ) {

		return 'position-${this.scope}';

	}

	public function generate( builder ) {

		let scope:String = this.scope;

		let outputNode:Node = null;

		if ( scope == PositionNode.GEOMETRY ) {

			outputNode = attribute( 'position', 'vec3' );

		} else if ( scope == PositionNode.LOCAL ) {

			outputNode = varying( positionGeometry );

		} else if ( scope == PositionNode.WORLD ) {

			let vertexPositionNode = modelWorldMatrix.mul( positionLocal );
			outputNode = varying( vertexPositionNode );

		} else if ( scope == PositionNode.VIEW ) {

			let vertexPositionNode = modelViewMatrix.mul( positionLocal );
			outputNode = varying( vertexPositionNode );

		} else if ( scope == PositionNode.VIEW_DIRECTION ) {

			let vertexPositionNode = positionView.negate();
			outputNode = normalize( varying( vertexPositionNode ) );

		} else if ( scope == PositionNode.WORLD_DIRECTION ) {

			let vertexPositionNode = positionLocal.transformDirection( modelWorldMatrix );
			outputNode = normalize( varying( vertexPositionNode ) );

		}

		return outputNode.build( builder, this.getNodeType( builder ) );

	}

	public function serialize( data ) {

		super.serialize( data );

		data.scope = this.scope;

	}

	public function deserialize( data ) {

		super.deserialize( data );

		this.scope = data.scope;

	}

}

export default PositionNode;

export var positionGeometry:Node = nodeImmutable( PositionNode, PositionNode.GEOMETRY );
export var positionLocal:Node = nodeImmutable( PositionNode, PositionNode.LOCAL ).temp( 'Position' );
export var positionWorld:Node = nodeImmutable( PositionNode, PositionNode.WORLD );
export var positionWorldDirection:Node = nodeImmutable( PositionNode, PositionNode.WORLD_DIRECTION );
export var positionView:Node = nodeImmutable( PositionNode, PositionNode.VIEW );
export var positionViewDirection:Node = nodeImmutable( PositionNode, PositionNode.VIEW_DIRECTION );

addNodeClass( 'PositionNode', PositionNode );