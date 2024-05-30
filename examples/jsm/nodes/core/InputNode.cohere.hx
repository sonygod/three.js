import Node from './Node.hx';
import { getValueType, getValueFromType, arrayBufferToBase64 } from './NodeUtils.hx';

class InputNode extends Node {

	public isInputNode:Bool;
	public value:Dynamic;
	public precision:Dynamic;

	public function new( value:Dynamic, nodeType:Dynamic = null ) {
		super( nodeType );
		this.isInputNode = true;
		this.value = value;
		this.precision = null;
	}

	public function getNodeType( builder:Dynamic ) : Dynamic {
		if ( this.nodeType == null ) {
			return getValueType( this.value );
		}
		return this.nodeType;
	}

	public function getInputType( builder:Dynamic ) : Dynamic {
		return this.getNodeType( builder );
	}

	public function setPrecision( precision:Dynamic ) : InputNode {
		this.precision = precision;
		return this;
	}

	public override function serialize( data:Dynamic ) : Void {
		super.serialize( data );
		data.value = this.value;
		if ( Reflect.hasField( this.value, 'toArray' ) ) {
			data.value = Reflect.field( this.value, 'toArray' );
		}
		data.valueType = getValueType( this.value );
		data.nodeType = this.nodeType;
		if ( data.valueType == 'ArrayBuffer' ) {
			data.value = arrayBufferToBase64( data.value );
		}
		data.precision = this.precision;
	}

	public override function deserialize( data:Dynamic ) : Void {
		super.deserialize( data );
		this.nodeType = data.nodeType;
		this.value = ( data.value is Array ) ? getValueFromType( data.valueType, data.value ) : data.value;
		this.precision = ( data.precision != null ) ? data.precision : null;
		if ( Reflect.hasField( this.value, 'fromArray' ) ) {
			this.value = Reflect.callMethod( this.value, 'fromArray', [ data.value ] );
		}
	}

	public function generate( builder:Dynamic, output:Dynamic ) : Void {
		trace( 'Abstract function.' );
	}

}

@:build( Node.registerNodeClass( 'InputNode', InputNode ) )
class InputNodeMeta {

}