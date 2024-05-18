class VRMLLexer {

	constructor( tokens ) {

		this.lexer = new chevrotain.Lexer( tokens );

	}

	lex( inputText ) {

		const lexingResult = this.lexer.tokenize( inputText );

		if ( lexingResult.errors.length > 0 ) {

			console.error( lexingResult.errors );

			throw Error( 'THREE.VRMLLexer: Lexing errors detected.' );

		}

		return lexingResult;

	}

}