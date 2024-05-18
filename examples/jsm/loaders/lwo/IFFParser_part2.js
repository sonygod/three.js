class DataViewReader {

	constructor( buffer ) {

		this.dv = new DataView( buffer );
		this.offset = 0;
		this._textDecoder = new TextDecoder();
		this._bytes = new Uint8Array( buffer );

	}

	size() {

		return this.dv.buffer.byteLength;

	}

	setOffset( offset ) {

		if ( offset > 0 && offset < this.dv.buffer.byteLength ) {

			this.offset = offset;

		} else {

			console.error( 'LWOLoader: invalid buffer offset' );

		}

	}

	endOfFile() {

		if ( this.offset >= this.size() ) return true;
		return false;

	}

	skip( length ) {

		this.offset += length;

	}

	getUint8() {

		var value = this.dv.getUint8( this.offset );
		this.offset += 1;
		return value;

	}

	getUint16() {

		var value = this.dv.getUint16( this.offset );
		this.offset += 2;
		return value;

	}

	getInt32() {

		var value = this.dv.getInt32( this.offset, false );
		this.offset += 4;
		return value;

	}

	getUint32() {

		var value = this.dv.getUint32( this.offset, false );
		this.offset += 4;
		return value;

	}

	getUint64() {

		var low, high;

		high = this.getUint32();
		low = this.getUint32();
		return high * 0x100000000 + low;

	}

	getFloat32() {

		var value = this.dv.getFloat32( this.offset, false );
		this.offset += 4;
		return value;

	}

	getFloat32Array( size ) {

		var a = [];

		for ( var i = 0; i < size; i ++ ) {

			a.push( this.getFloat32() );

		}

		return a;

	}

	getFloat64() {

		var value = this.dv.getFloat64( this.offset, this.littleEndian );
		this.offset += 8;
		return value;

	}

	getFloat64Array( size ) {

		var a = [];

		for ( var i = 0; i < size; i ++ ) {

			a.push( this.getFloat64() );

		}

		return a;

	}

	// get variable-length index data type
	// VX ::= index[U2] | (index + 0xFF000000)[U4]
	// If the index value is less than 65,280 (0xFF00),then VX === U2
	// otherwise VX === U4 with bits 24-31 set
	// When reading an index, if the first byte encountered is 255 (0xFF), then
	// the four-byte form is being used and the first byte should be discarded or masked out.
	getVariableLengthIndex() {

		var firstByte = this.getUint8();

		if ( firstByte === 255 ) {

			return this.getUint8() * 65536 + this.getUint8() * 256 + this.getUint8();

		}

		return firstByte * 256 + this.getUint8();

	}

	// An ID tag is a sequence of 4 bytes containing 7-bit ASCII values
	getIDTag() {

		return this.getString( 4 );

	}

	getString( size ) {

		if ( size === 0 ) return;

		const start = this.offset;

		let result;
		let length;

		if ( size ) {

			length = size;
			result = this._textDecoder.decode( new Uint8Array( this.dv.buffer, start, size ) );

		} else {

			// use 1:1 mapping of buffer to avoid redundant new array creation.
			length = this._bytes.indexOf( 0, start ) - start;

			result = this._textDecoder.decode( new Uint8Array( this.dv.buffer, start, length ) );

			// account for null byte in length
			length ++;

			// if string with terminating nullbyte is uneven, extra nullbyte is added, skip that too
			length += length % 2;

		}

		this.skip( length );

		return result;

	}

	getStringArray( size ) {

		var a = this.getString( size );
		a = a.split( '\0' );

		return a.filter( Boolean ); // return array with any empty strings removed

	}

}