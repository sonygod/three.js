import three.math.Color;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.core.FileLoader;
import three.core.Loader;
import js.typedarrays.TypedArray;
import js.typedarrays.Uint8Array;
import js.typedarrays.DataView;
import js.flash.XML;
import js.flash.XMLList;
import js.Boot;
import js.Json;
import js.html.DOMParser;
import js.html.Element;

import fflate.Unzip;
import fflate.DecodeStream;

class VTKLoader extends Loader {

	public function new( manager:Loader.Manager ) {
		super( manager );
	}

	public override function load( url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic ):Void {
		var scope = this;
		var loader = new FileLoader( scope.manager );
		loader.setPath( scope.path );
		loader.setResponseType( 'arraybuffer' );
		loader.setRequestHeader( scope.requestHeader );
		loader.setWithCredentials( scope.withCredentials );
		loader.load( url, function ( text:TypedArray ) {

			try {

				onLoad( scope.parse( text ) );

			} catch ( e:Dynamic ) {

				if ( onError != null ) {

					onError( e );

				} else {

					Sys.println( Std.string( e ) );

				}

				scope.manager.itemError( url );

			}

		}, onProgress, onError );
	}

	public function parse( data:TypedArray ):BufferGeometry {

		function parseASCII( data:TypedArray ):BufferGeometry {

			// connectivity of the triangles
			var indices:Array<Int> = [];

			// triangles vertices
			var positions:Array<Float> = [];

			// red, green, blue colors in the range 0 to 1
			var colors:Array<Float> = [];

			// normal vector, one per vertex
			var normals:Array<Float> = [];

			var result:Dynamic;

			// pattern for detecting the end of a number sequence
			var patWord = /^[^\d.\s-]+/;

			// pattern for reading vertices, 3 floats or integers
			var pat3Floats = /(\-?\d+\.?[\d\-\+e]*)\s+(\-?\d+\.?[\d\-\+e]*)\s+(\-?\d+\.?[\d\-\+e]*)/g;

			// pattern for connectivity, an integer followed by any number of ints
			// the first integer is the number of polygon nodes
			var patConnectivity = /(\d+)\s+([\s\d]*)/;

			// indicates start of vertex data section
			var patPOINTS = /^POINTS /;

			// indicates start of polygon connectivity section
			var patPOLYGONS = /^POLYGONS /;

			// indicates start of triangle strips section
			var patTRIANGLE_STRIPS = /^TRIANGLE_STRIPS /;

			// POINT_DATA number_of_values
			var patPOINT_DATA = /^POINT_DATA[ ]+(\d+)/;

			// CELL_DATA number_of_polys
			var patCELL_DATA = /^CELL_DATA[ ]+(\d+)/;

			// Start of color section
			var patCOLOR_SCALARS = /^COLOR_SCALARS[ ]+(\w+)[ ]+3/;

			// NORMALS Normals float
			var patNORMALS = /^NORMALS[ ]+(\w+)[ ]+(\w+)/;

			var inPointsSection = false;
			var inPolygonsSection = false;
			var inTriangleStripSection = false;
			var inPointDataSection = false;
			var inCellDataSection = false;
			var inColorSection = false;
			var inNormalsSection = false;

			var color = new Color();

			var lines = data.split( '\n' );

			for ( var i in lines ) {

				var line = lines[ i ].trim();

				if ( line.indexOf( 'DATASET' ) === 0 ) {

					var dataset = line.split( ' ' )[ 1 ];

					if ( dataset !== 'POLYDATA' ) throw new Error( 'Unsupported DATASET type: ' + dataset );

				} else if ( inPointsSection ) {

					// get the vertices
					while ( ( result = pat3Floats.exec( line ) ) !== null ) {

						if ( patWord.exec( line ) !== null ) break;

						var x = parseFloat( result[ 1 ] );
						var y = parseFloat( result[ 2 ] );
						var z = parseFloat( result[ 3 ] );
						positions.push( x, y, z );

					}

				} else if ( inPolygonsSection ) {

					if ( ( result = patConnectivity.exec( line ) ) !== null ) {

						// numVertices i0 i1 i2 ...
						var numVertices = parseInt( result[ 1 ] );
						var inds = result[ 2 ].split( /\s+/ );

						if ( numVertices >= 3 ) {

							var i0 = parseInt( inds[ 0 ] );
							var k = 1;
							// split the polygon in numVertices - 2 triangles
							for ( var j = 0; j < numVertices - 2; ++ j ) {

								var i1 = parseInt