import FileLoader.FileLoader;
import Loader.Loader;
import opentype.opentype;

/**
 * Requires opentype.js to be included in the project.
 * Loads TTF files and converts them into typeface JSON that can be used directly
 * to create THREE.Font objects.
 */

class TTFLoader extends Loader {

	public var reversed:Bool;

	public function new( manager:Loader.LoaderManager ) {

		super( manager );

		this.reversed = false;

	}

	public function load( url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic ) {

		var scope = this;

		var loader = new FileLoader( this.manager );
		loader.setPath( this.path );
		loader.setResponseType( 'arraybuffer' );
		loader.setRequestHeader( this.requestHeader );
		loader.setWithCredentials( this.withCredentials );
		loader.load( url, function ( buffer ) {

			try {

				onLoad( scope.parse( buffer ) );

			} catch ( e ) {

				if ( onError ) {

					onError( e );

				} else {

					Sys.println( e );

				}

				scope.manager.itemError( url );

			}

		}, onProgress, onError );

	}

	public function parse( arraybuffer:haxe.io.Bytes ) {

		function convert( font:Dynamic, reversed:Bool ) {

			var round = Math.round;

			var glyphs = new haxe.ds.StringMap();
			var scale = ( 100000 ) / ( ( font.unitsPerEm || 2048 ) * 72 );

			var glyphIndexMap = font.encoding.cmap.glyphIndexMap;
			var unicodes = Reflect.fields( glyphIndexMap );

			for ( unicode in unicodes ) {

				var unicode = unicodes[ unicode ];
				var glyph = font.glyphs.glyphs[ glyphIndexMap[ unicode ] ];

				if ( unicode !== undefined ) {

					var token = {
						ha: round( glyph.advanceWidth * scale ),
						x_min: round( glyph.xMin * scale ),
						x_max: round( glyph.xMax * scale ),
						o: ''
					};

					if ( reversed ) {

						glyph.path.commands = reverseCommands( glyph.path.commands );

					}

					glyph.path.commands.forEach( function ( command ) {

						if ( command.type.toLowerCase() === 'c' ) {

							command.type = 'b';

						}

						token.o += command.type.toLowerCase() + ' ';

						if ( command.x !== undefined && command.y !== undefined ) {

							token.o += round( command.x * scale ) + ' ' + round( command.y * scale ) + ' ';

						}

						if ( command.x1 !== undefined && command.y1 !== undefined ) {

							token.o += round( command.x1 * scale ) + ' ' + round( command.y1 * scale ) + ' ';

						}

						if ( command.x2 !== undefined && command.y2 !== undefined ) {

							token.o += round( command.x2 * scale ) + ' ' + round( command.y2 * scale ) + ' ';

						}

					} );

					glyphs.set( String.fromCodePoint( glyph.unicode ), token );

				}

			}

			return {
				glyphs: glyphs,
				familyName: font.getEnglishName( 'fullName' ),
				ascender: round( font.ascender * scale ),
				descender: round( font.descender * scale ),
				underlinePosition: font.tables.post.underlinePosition,
				underlineThickness: font.tables.post.underlineThickness,
				boundingBox: {
					xMin: font.tables.head.xMin,
					xMax: font.tables.head.xMax,
					yMin: font.tables.head.yMin,
					yMax: font.tables.head.yMax
				},
				resolution: 1000,
				original_font_information: font.tables.name
			};

		}

		function reverseCommands( commands:Array<Dynamic> ) {

			var paths = [];
			var path;

			commands.forEach( function ( c ) {

				if ( c.type.toLowerCase() === 'm' ) {

					path = [ c ];
					paths.push( path );

				} else if ( c.type.toLowerCase() !== 'z' ) {

					path.push( c );

				}

			} );

			var reversed = [];

			paths.forEach( function ( p ) {

				var result = {
					type: 'm',
					x: p[ p.length - 1 ].x,
					y: p[ p.length - 1 ].y
				};

				reversed.push( result );

				for ( i in ( p.length - 1 )..1 ) {

					var command = p[ i ];
					var result = { type: command.type };

					if ( command.x2 !== undefined && command.y2 !== undefined ) {

						result.x1 = command.x2;
						result.y1 = command.y2;
						result.x2 = command.x1;
						result.y2 = command.y1;

					} else if ( command.x1 !== undefined && command.y1 !== undefined ) {

						result.x1 = command.x1;
						result.y1 = command.y1;

					}

					result.x = p[ i - 1 ].x;
					result.y = p[ i - 1 ].y;
					reversed.push( result );

				}

			} );

			return reversed;

		}

		return convert( opentype.parse( arraybuffer ), this.reversed );

	}

}

export class TTFLoader;