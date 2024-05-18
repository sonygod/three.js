class Debugger {

	constructor() {

		this.active = false;
		this.depth = 0;
		this.formList = [];

	}

	enable() {

		this.active = true;

	}

	log() {

		if ( ! this.active ) return;

		var nodeType;

		switch ( this.node ) {

			case 0:
				nodeType = 'FORM';
				break;

			case 1:
				nodeType = 'CHK';
				break;

			case 2:
				nodeType = 'S-CHK';
				break;

		}

		console.log(
			'| '.repeat( this.depth ) +
			nodeType,
			this.nodeID,
			`( ${this.offset} ) -> ( ${this.dataOffset + this.length} )`,
			( ( this.node == 0 ) ? ' {' : '' ),
			( ( this.skipped ) ? 'SKIPPED' : '' ),
			( ( this.node == 0 && this.skipped ) ? '}' : '' )
		);

		if ( this.node == 0 && ! this.skipped ) {

			this.depth += 1;
			this.formList.push( this.dataOffset + this.length );

		}

		this.skipped = false;

	}

	closeForms() {

		if ( ! this.active ) return;

		for ( var i = this.formList.length - 1; i >= 0; i -- ) {

			if ( this.offset >= this.formList[ i ] ) {

				this.depth -= 1;
				console.log( '| '.repeat( this.depth ) + '}' );
				this.formList.splice( - 1, 1 );

			}

		}

	}

}