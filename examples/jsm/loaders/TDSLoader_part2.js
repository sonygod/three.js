class Chunk {

	/**
	 * Create a new chunk
	 *
	 * @class Chunk
	 * @param {DataView} data DataView to read from.
	 * @param {Number} position in data.
	 * @param {Function} debugMessage logging callback.
	 */
	constructor( data, position, debugMessage ) {

		this.data = data;
		// the offset to the begin of this chunk
		this.offset = position;
		// the current reading position
		this.position = position;
		this.debugMessage = debugMessage;

		if ( this.debugMessage instanceof Function ) {

			this.debugMessage = function () {};

		}

		this.id = this.readWord();
		this.size = this.readDWord();
		this.end = this.offset + this.size;

		if ( this.end > data.byteLength ) {

			this.debugMessage( 'Bad chunk size for chunk at ' + position );

		}

	}

	/**
	 * read a sub cchunk.
	 *
	 * @method readChunk
	 * @return {Chunk | null} next sub chunk
	 */
	readChunk() {

		if ( this.endOfChunk ) {

			return null;

		}

		try {

			const next = new Chunk( this.data, this.position, this.debugMessage );
			this.position += next.size;
			return next;

		}	catch ( e ) {

			this.debugMessage( 'Unable to read chunk at ' + this.position );
			return null;

		}

	}

	/**
	 * return the ID of this chunk as Hex
	 *
	 * @method idToString
	 * @return {String} hex-string of id
	 */
	get hexId() {

		return this.id.toString( 16 );

	}

	get endOfChunk() {

		return this.position >= this.end;

	}

	/**
	 * Read byte value.
	 *
	 * @method readByte
	 * @return {Number} Data read from the dataview.
	 */
	readByte() {

		const v = this.data.getUint8( this.position, true );
		this.position += 1;
		return v;

	}

	/**
	 * Read 32 bit float value.
	 *
	 * @method readFloat
	 * @return {Number} Data read from the dataview.
	 */
	readFloat() {

		try {

			const v = this.data.getFloat32( this.position, true );
			this.position += 4;
			return v;

		}	catch ( e ) {

			this.debugMessage( e + ' ' + this.position + ' ' + this.data.byteLength );
			return 0;

		}

	}

	/**
	 * Read 32 bit signed integer value.
	 *
	 * @method readInt
	 * @return {Number} Data read from the dataview.
	 */
	readInt() {

		const v = this.data.getInt32( this.position, true );
		this.position += 4;
		return v;

	}

	/**
	 * Read 16 bit signed integer value.
	 *
	 * @method readShort
	 * @return {Number} Data read from the dataview.
	 */
	readShort() {

		const v = this.data.getInt16( this.position, true );
		this.position += 2;
		return v;

	}

	/**
	 * Read 64 bit unsigned integer value.
	 *
	 * @method readDWord
	 * @return {Number} Data read from the dataview.
	 */
	readDWord() {

		const v = this.data.getUint32( this.position, true );
		this.position += 4;
		return v;

	}

	/**
	 * Read 32 bit unsigned integer value.
	 *
	 * @method readWord
	 * @return {Number} Data read from the dataview.
	 */
	readWord() {

		const v = this.data.getUint16( this.position, true );
		this.position += 2;
		return v;

	}

	/**
	 * Read NULL terminated ASCII string value from chunk-pos.
	 *
	 * @method readString
	 * @return {String} Data read from the dataview.
	 */
	readString() {

		let s = '';
		let c = this.readByte();
		while ( c ) {

			s += String.fromCharCode( c );
			c = this.readByte();

		}

		return s;

	}

}