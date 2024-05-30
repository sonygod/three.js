import TempNode from '../core/TempNode.js';
import { addNodeClass } from '../core/Node.js';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';

class PackingNode extends TempNode {

	public var scope:String;
	public var node:Dynamic;

	public function new( scope:String, node:Dynamic ) {

		super();

		this.scope = scope;
		this.node = node;

	}

	public function getNodeType( builder:Dynamic ) {

		return this.node.getNodeType( builder );

	}

	public function setup() {

		var { scope, node } = this;

		var result:Dynamic = null;

		if ( scope == PackingNode.DIRECTION_TO_COLOR ) {

			result = node.mul( 0.5 ).add( 0.5 );

		} else if ( scope == PackingNode.COLOR_TO_DIRECTION ) {

			result = node.mul( 2.0 ).sub( 1 );

		}

		return result;

	}

}

PackingNode.DIRECTION_TO_COLOR = 'directionToColor';
PackingNode.COLOR_TO_DIRECTION = 'colorToDirection';

@:expose
@:keep
class PackingNodeClass {

	public static var DIRECTION_TO_COLOR:String = PackingNode.DIRECTION_TO_COLOR;
	public static var COLOR_TO_DIRECTION:String = PackingNode.COLOR_TO_DIRECTION;

	public static function directionToColor( node:Dynamic ) {

		return nodeProxy( PackingNode, PackingNode.DIRECTION_TO_COLOR, node );

	}

	public static function colorToDirection( node:Dynamic ) {

		return nodeProxy( PackingNode, PackingNode.COLOR_TO_DIRECTION, node );

	}

	public static function addNodeElement( name:String, node:Dynamic ) {

		addNodeElement( name, node );

	}

	public static function addNodeClass( name:String, node:Dynamic ) {

		addNodeClass( name, node );

	}

}

addNodeElement( 'directionToColor', PackingNodeClass.directionToColor );
addNodeElement( 'colorToDirection', PackingNodeClass.colorToDirection );

addNodeClass( 'PackingNode', PackingNode );