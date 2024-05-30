import Node, { addNodeClass } from './Node.js';
import { addNodeElement, nodeProxy } from '../shadernode/ShaderNode.js';

class ContextNode extends Node {

	public var isContextNode:Bool = true;
	public var node:Node;
	public var context:Dynamic;

	public function new( node:Node, context:Dynamic = {} ) {

		super();

		this.node = node;
		this.context = context;

	}

	public function getNodeType( builder:Dynamic ):Dynamic {

		return this.node.getNodeType( builder );

	}

	public function setup( builder:Dynamic ):Dynamic {

		var previousContext = builder.getContext();

		builder.setContext( { ...builder.context, ...this.context } );

		var node = this.node.build( builder );

		builder.setContext( previousContext );

		return node;

	}

	public function generate( builder:Dynamic, output:Dynamic ):Dynamic {

		var previousContext = builder.getContext();

		builder.setContext( { ...builder.context, ...this.context } );

		var snippet = this.node.build( builder, output );

		builder.setContext( previousContext );

		return snippet;

	}

}

export default ContextNode;

export var context = nodeProxy( ContextNode );
export var label = ( node:Node, name:String ) => context( node, { label: name } );

addNodeElement( 'context', context );
addNodeElement( 'label', label );

addNodeClass( 'ContextNode', ContextNode );