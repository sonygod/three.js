import Node, { addNodeClass } from './Node.js';
import StructTypeNode from './StructTypeNode.js';
import { nodeProxy } from '../shadernode/ShaderNode.js';

class OutputStructNode extends Node {

	public var members:Array<Dynamic>;

	public var isOutputStructNode:Bool = true;

	public function new( ...members ) {

		super();

		this.members = members;

	}

	public function setup( builder ) {

		super.setup( builder );

		var types:Array<Dynamic> = [];

		for ( i in 0...members.length ) {

			types.push( members[ i ].getNodeType( builder ) );

		}

		this.nodeType = builder.getStructTypeFromNode( new StructTypeNode( types ) ).name;

	}

	public function generate( builder, output ) {

		var nodeVar = builder.getVarFromNode( this );
		nodeVar.isOutputStructVar = true;

		var propertyName = builder.getPropertyName( nodeVar );

		var structPrefix = propertyName !== '' ? propertyName + '.' : '';

		for ( i in 0...members.length ) {

			var snippet = members[ i ].build( builder, output );

			builder.addLineFlowCode( "${structPrefix}m${i} = ${snippet}" );

		}

		return propertyName;

	}

}

export default OutputStructNode;

export const outputStruct = nodeProxy( OutputStructNode );

addNodeClass( 'OutputStructNode', OutputStructNode );