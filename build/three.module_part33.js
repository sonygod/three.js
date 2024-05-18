class Int32BufferAttribute extends BufferAttribute {

	constructor( array, itemSize, normalized ) {

		super( new Int32Array( array ), itemSize, normalized );

	}

}