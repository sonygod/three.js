class Uint8BufferAttribute extends BufferAttribute {

	constructor( array, itemSize, normalized ) {

		super( new Uint8Array( array ), itemSize, normalized );

	}

}