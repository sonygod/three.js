import FogNode from './FogNode.hx';
import { smoothstep } from '../math/MathNode.hx';
import { addNodeClass } from '../core/Node.hx';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.hx';

class FogRangeNode extends FogNode {
	public isFogRangeNode:Bool;
	public nearNode:Float;
	public farNode:Float;

	public function new( colorNode:Dynamic, nearNode:Dynamic, farNode:Dynamic ) {
		super( colorNode );
		this.isFogRangeNode = true;
		this.nearNode = nearNode;
		this.farNode = farNode;
	}

	public function setup( builder:Dynamic ) -> Dynamic {
		var viewZ = this.getViewZNode( builder );
		return smoothstep( this.nearNode, this.farNode, viewZ );
	}
}

@:export( default )
static function FogRangeNode_get_default() -> FogRangeNode {
	return FogRangeNode;
}

@:export( rangeFog )
static function rangeFog() -> FogRangeNode {
	return nodeProxy( FogRangeNode );
}

addNodeElement( 'rangeFog', rangeFog );
addNodeClass( 'FogRangeNode', FogRangeNode );