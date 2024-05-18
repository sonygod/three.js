class VRMLParser extends CstParser {

	constructor( tokenVocabulary ) {

		super( tokenVocabulary );

		const $ = this;

		const Version = tokenVocabulary[ 'Version' ];
		const LCurly = tokenVocabulary[ 'LCurly' ];
		const RCurly = tokenVocabulary[ 'RCurly' ];
		const LSquare = tokenVocabulary[ 'LSquare' ];
		const RSquare = tokenVocabulary[ 'RSquare' ];
		const Identifier = tokenVocabulary[ 'Identifier' ];
		const RouteIdentifier = tokenVocabulary[ 'RouteIdentifier' ];
		const StringLiteral = tokenVocabulary[ 'StringLiteral' ];
		const HexLiteral = tokenVocabulary[ 'HexLiteral' ];
		const NumberLiteral = tokenVocabulary[ 'NumberLiteral' ];
		const TrueLiteral = tokenVocabulary[ 'TrueLiteral' ];
		const FalseLiteral = tokenVocabulary[ 'FalseLiteral' ];
		const NullLiteral = tokenVocabulary[ 'NullLiteral' ];
		const DEF = tokenVocabulary[ 'DEF' ];
		const USE = tokenVocabulary[ 'USE' ];
		const ROUTE = tokenVocabulary[ 'ROUTE' ];
		const TO = tokenVocabulary[ 'TO' ];
		const NodeName = tokenVocabulary[ 'NodeName' ];

		$.RULE( 'vrml', function () {

			$.SUBRULE( $.version );
			$.AT_LEAST_ONE( function () {

				$.SUBRULE( $.node );

			} );
			$.MANY( function () {

				$.SUBRULE( $.route );

			} );

		} );

		$.RULE( 'version', function () {

			$.CONSUME( Version );

		} );

		$.RULE( 'node', function () {

			$.OPTION( function () {

				$.SUBRULE( $.def );

			} );

			$.CONSUME( NodeName );
			$.CONSUME( LCurly );
			$.MANY( function () {

				$.SUBRULE( $.field );

			} );
			$.CONSUME( RCurly );

		} );

		$.RULE( 'field', function () {

			$.CONSUME( Identifier );

			$.OR2( [
				{ ALT: function () {

					$.SUBRULE( $.singleFieldValue );

				} },
				{ ALT: function () {

					$.SUBRULE( $.multiFieldValue );

				} }
			] );

		} );

		$.RULE( 'def', function () {

			$.CONSUME( DEF );
			$.OR( [
				{ ALT: function () {

					$.CONSUME( Identifier );

				} },
				{ ALT: function () {

					$.CONSUME( NodeName );

				} }
			] );

		} );

		$.RULE( 'use', function () {

			$.CONSUME( USE );
			$.OR( [
				{ ALT: function () {

					$.CONSUME( Identifier );

				} },
				{ ALT: function () {

					$.CONSUME( NodeName );

				} }
			] );

		} );

		$.RULE( 'singleFieldValue', function () {

			$.AT_LEAST_ONE( function () {

				$.OR( [
					{ ALT: function () {

						$.SUBRULE( $.node );

					} },
					{ ALT: function () {

						$.SUBRULE( $.use );

					} },
					{ ALT: function () {

						$.CONSUME( StringLiteral );

					} },
					{ ALT: function () {

						$.CONSUME( HexLiteral );

					} },
					{ ALT: function () {

						$.CONSUME( NumberLiteral );

					} },
					{ ALT: function () {

						$.CONSUME( TrueLiteral );

					} },
					{ ALT: function () {

						$.CONSUME( FalseLiteral );

					} },
					{ ALT: function () {

						$.CONSUME( NullLiteral );

					} }
				] );


			} );

		} );

		$.RULE( 'multiFieldValue', function () {

			$.CONSUME( LSquare );
			$.MANY( function () {

				$.OR( [
					{ ALT: function () {

						$.SUBRULE( $.node );

					} },
					{ ALT: function () {

						$.SUBRULE( $.use );

					} },
					{ ALT: function () {

						$.CONSUME( StringLiteral );

					} },
					{ ALT: function () {

						$.CONSUME( HexLiteral );

					} },
					{ ALT: function () {

						$.CONSUME( NumberLiteral );

					} },
					{ ALT: function () {

						$.CONSUME( NullLiteral );

					} }
				] );

			} );
			$.CONSUME( RSquare );

		} );

		$.RULE( 'route', function () {

			$.CONSUME( ROUTE );
			$.CONSUME( RouteIdentifier );
			$.CONSUME( TO );
			$.CONSUME2( RouteIdentifier );

		} );

		this.performSelfAnalysis();

	}

}