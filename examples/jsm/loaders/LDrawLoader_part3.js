class LineParser {

	constructor( line, lineNumber ) {

		this.line = line;
		this.lineLength = line.length;
		this.currentCharIndex = 0;
		this.currentChar = ' ';
		this.lineNumber = lineNumber;

	}

	seekNonSpace() {

		while ( this.currentCharIndex < this.lineLength ) {

			this.currentChar = this.line.charAt( this.currentCharIndex );

			if ( this.currentChar !== ' ' && this.currentChar !== '\t' ) {

				return;

			}

			this.currentCharIndex ++;

		}

	}

	getToken() {

		const pos0 = this.currentCharIndex ++;

		// Seek space
		while ( this.currentCharIndex < this.lineLength ) {

			this.currentChar = this.line.charAt( this.currentCharIndex );

			if ( this.currentChar === ' ' || this.currentChar === '\t' ) {

				break;

			}

			this.currentCharIndex ++;

		}

		const pos1 = this.currentCharIndex;

		this.seekNonSpace();

		return this.line.substring( pos0, pos1 );

	}

	getVector() {

		return new Vector3( parseFloat( this.getToken() ), parseFloat( this.getToken() ), parseFloat( this.getToken() ) );

	}

	getRemainingString() {

		return this.line.substring( this.currentCharIndex, this.lineLength );

	}

	isAtTheEnd() {

		return this.currentCharIndex >= this.lineLength;

	}

	setToEnd() {

		this.currentCharIndex = this.lineLength;

	}

	getLineNumberString() {

		return this.lineNumber >= 0 ? ' at line ' + this.lineNumber : '';

	}

}