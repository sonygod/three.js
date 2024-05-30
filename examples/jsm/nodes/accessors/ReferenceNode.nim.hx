import Node, { addNodeClass } from '../core/Node.js';
import { NodeUpdateType } from '../core/constants.js';
import { uniform } from '../core/UniformNode.js';
import { texture } from './TextureNode.js';
import { buffer } from './BufferNode.js';
import { nodeObject } from '../shadernode/ShaderNode.js';
import { uniforms } from './UniformsNode.js';
import ArrayElementNode from '../utils/ArrayElementNode.js';

class ReferenceElementNode extends ArrayElementNode {

	public var referenceNode:Node;

	public function new( referenceNode:Node, indexNode:Node ) {

		super( referenceNode, indexNode );

		this.referenceNode = referenceNode;

		this.isReferenceElementNode = true;

	}

	public function getNodeType():String {

		return this.referenceNode.uniformType;

	}

	public function generate( builder:String ):String {

		const snippet = super.generate( builder );
		const arrayType = this.referenceNode.getNodeType();
		const elementType = this.getNodeType();

		return builder.format( snippet, arrayType, elementType );

	}

}

class ReferenceNode extends Node {

	public var property:String;
	public var uniformType:String;
	public var object:Null<Dynamic>;
	public var count:Null<Int>;

	public var properties:Array<String>;
	public var reference:Null<Dynamic>;
	public var node:Null<Node>;

	public function new( property:String, uniformType:String, object:Null<Dynamic> = null, count:Null<Int> = null ) {

		super();

		this.property = property;
		this.uniformType = uniformType;
		this.object = object;
		this.count = count;

		this.properties = property.split( '.' );
		this.reference = null;
		this.node = null;

		this.updateType = NodeUpdateType.OBJECT;

	}

	public function element( indexNode:Node ):Node {

		return nodeObject( new ReferenceElementNode( this, nodeObject( indexNode ) ) );

	}

	public function setNodeType( uniformType:String ):Void {

		var node:Null<Node> = null;

		if ( this.count !== null ) {

			node = buffer( null, uniformType, this.count );

		} else if ( Array.isArray( this.getValueFromReference() ) ) {

			node = uniforms( null, uniformType );

		} else if ( uniformType === 'texture' ) {

			node = texture( null );

		} else {

			node = uniform( null, uniformType );

		}

		this.node = node;

	}

	public function getNodeType( builder:String ):String {

		return this.node.getNodeType( builder );

	}

	public function getValueFromReference( object:Null<Dynamic> = this.reference ):Dynamic {

		const { properties } = this;

		let value:Dynamic = object[ properties[ 0 ] ];

		for ( i in 1...properties.length ) {

			value = value[ properties[ i ] ];

		}

		return value;

	}

	public function updateReference( state:Dynamic ):Dynamic {

		this.reference = this.object !== null ? this.object : state.object;

		return this.reference;

	}

	public function setup():Node {

		this.updateValue();

		return this.node;

	}

	public function update( /*frame*/ ):Void {

		this.updateValue();

	}

	public function updateValue():Void {

		if ( this.node === null ) this.setNodeType( this.uniformType );

		const value:Dynamic = this.getValueFromReference();

		if ( Array.isArray( value ) ) {

			this.node.array = value;

		} else {

			this.node.value = value;

		}

	}

}

export default ReferenceNode;

export function reference( name:String, type:String, object:Dynamic ):Node {

	return nodeObject( new ReferenceNode( name, type, object ) );

}

export function referenceBuffer( name:String, type:String, count:Int, object:Dynamic ):Node {

	return nodeObject( new ReferenceNode( name, type, object, count ) );

}

addNodeClass( 'ReferenceNode', ReferenceNode );