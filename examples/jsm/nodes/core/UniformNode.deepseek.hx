import InputNode from './InputNode.js';
import { objectGroup } from './UniformGroupNode.js';
import { addNodeClass } from './Node.js';
import { nodeObject, getConstNodeType } from '../shadernode/ShaderNode.js';

class UniformNode extends InputNode {

	public function new( value, nodeType = null ) {

		super( value, nodeType );

		this.isUniformNode = true;

		this.groupNode = objectGroup;

	}

	public function setGroup( group ) {

		this.groupNode = group;

		return this;

	}

	public function getGroup() {

		return this.groupNode;

	}

	public function getUniformHash( builder ) {

		return this.getHash( builder );

	}

	public function onUpdate( callback, updateType ) {

		var self = this.getSelf();

		callback = callback.bind( self );

		return super.onUpdate( ( frame ) -> {

			var value = callback( frame, self );

			if ( value !== undefined ) {

				this.value = value;

			}

	 	}, updateType );

	}

	public function generate( builder, output ) {

		var type = this.getNodeType( builder );

		var hash = this.getUniformHash( builder );

		var sharedNode = builder.getNodeFromHash( hash );

		if ( sharedNode === undefined ) {

			builder.setHashNode( this, hash );

			sharedNode = this;

		}

		var sharedNodeType = sharedNode.getInputType( builder );

		var nodeUniform = builder.getUniformFromNode( sharedNode, sharedNodeType, builder.shaderStage, builder.context.label );
		var propertyName = builder.getPropertyName( nodeUniform );

		if ( builder.context.label !== undefined ) delete builder.context.label;

		return builder.format( propertyName, type, output );

	}

}

export default UniformNode;

export function uniform( arg1, arg2 ) {

	var nodeType = getConstNodeType( arg2 || arg1 );

	// @TODO: get ConstNode from .traverse() in the future
	var value = ( arg1 && arg1.isNode === true ) ? ( arg1.node && arg1.node.value ) || arg1.value : arg1;

	return nodeObject( new UniformNode( value, nodeType ) );

};

addNodeClass( 'UniformNode', UniformNode );