import Node, { addNodeClass } from './Node.js';
import { varying } from './VaryingNode.js';
import { nodeImmutable } from '../shadernode/ShaderNode.js';

class IndexNode extends Node {

	public var scope:String;

	public var isInstanceIndexNode:Bool = true;

	public function new( scope:String ) {

		super('uint');

		this.scope = scope;

	}

	public function generate( builder ) {

		var nodeType = this.getNodeType( builder );
		var scope = this.scope;

		var propertyName;

		if ( scope == IndexNode.VERTEX ) {

			propertyName = builder.getVertexIndex();

		} else if ( scope == IndexNode.INSTANCE ) {

			propertyName = builder.getInstanceIndex();

		} else {

			throw new Error( 'THREE.IndexNode: Unknown scope: ' + scope );

		}

		var output;

		if ( builder.shaderStage == 'vertex' || builder.shaderStage == 'compute' ) {

			output = propertyName;

		} else {

			var nodeVarying = varying( this );

			output = nodeVarying.build( builder, nodeType );

		}

		return output;

	}

}

IndexNode.VERTEX = 'vertex';
IndexNode.INSTANCE = 'instance';

@:expose
class IndexNodeClass {

	public static var VERTEX:String = IndexNode.VERTEX;
	public static var INSTANCE:String = IndexNode.INSTANCE;

	public static function new( scope:String ) {

		return new IndexNode( scope );

	}

}

addNodeClass( 'IndexNode', IndexNodeClass );

export var vertexIndex = nodeImmutable( IndexNode, IndexNode.VERTEX );
export var instanceIndex = nodeImmutable( IndexNode, IndexNode.INSTANCE );