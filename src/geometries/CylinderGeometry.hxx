import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;
import three.math.Vector2;

class CylinderGeometry extends BufferGeometry {

	public function new(radiusTop:Float = 1, radiusBottom:Float = 1, height:Float = 1, radialSegments:Int = 32, heightSegments:Int = 1, openEnded:Bool = false, thetaStart:Float = 0, thetaLength:Float = Math.PI * 2) {

		super();

		this.type = 'CylinderGeometry';

		this.parameters = {
			radiusTop: radiusTop,
			radiusBottom: radiusBottom,
			height: height,
			radialSegments: radialSegments,
			heightSegments: heightSegments,
			openEnded: openEnded,
			thetaStart: thetaStart,
			thetaLength: thetaLength
		};

		var scope = this;

		radialSegments = Math.floor( radialSegments );
		heightSegments = Math.floor( heightSegments );

		// buffers

		var indices = [];
		var vertices = [];
		var normals = [];
		var uvs = [];

		// helper variables

		var index = 0;
		var indexArray = [];
		var halfHeight = height / 2;
		var groupStart = 0;

		// generate geometry

		generateTorso();

		if ( openEnded == false ) {

			if ( radiusTop > 0 ) generateCap( true );
			if ( radiusBottom > 0 ) generateCap( false );

		}

		// build geometry

		this.setIndex( indices );
		this.setAttribute( 'position', new BufferAttribute( vertices, 3 ) );
		this.setAttribute( 'normal', new BufferAttribute( normals, 3 ) );
		this.setAttribute( 'uv', new BufferAttribute( uvs, 2 ) );

		function generateTorso() {

			var normal = new Vector3();
			var vertex = new Vector3();

			var groupCount = 0;

			// this will be used to calculate the normal
			var slope = ( radiusBottom - radiusTop ) / height;

			// generate vertices, normals and uvs

			for ( y in 0...heightSegments+1 ) {

				var indexRow = [];

				var v = y / heightSegments;

				// calculate the radius of the current row

				var radius = v * ( radiusBottom - radiusTop ) + radiusTop;

				for ( x in 0...radialSegments+1 ) {

					var u = x / radialSegments;

					var theta = u * thetaLength + thetaStart;

					var sinTheta = Math.sin( theta );
					var cosTheta = Math.cos( theta );

					// vertex

					vertex.x = radius * sinTheta;
					vertex.y = - v * height + halfHeight;
					vertex.z = radius * cosTheta;
					vertices.push( vertex.x, vertex.y, vertex.z );

					// normal

					normal.set( sinTheta, slope, cosTheta ).normalize();
					normals.push( normal.x, normal.y, normal.z );

					// uv

					uvs.push( u, 1 - v );

					// save index of vertex in respective row

					indexRow.push( index ++ );

				}

				// now save vertices of the row in our index array

				indexArray.push( indexRow );

			}

			// generate indices

			for ( x in 0...radialSegments ) {

				for ( y in 0...heightSegments ) {

					// we use the index array to access the correct indices

					var a = indexArray[ y ][ x ];
					var b = indexArray[ y + 1 ][ x ];
					var c = indexArray[ y + 1 ][ x + 1 ];
					var d = indexArray[ y ][ x + 1 ];

					// faces

					indices.push( a, b, d );
					indices.push( b, c, d );

					// update group counter

					groupCount += 6;

				}

			}

			// add a group to the geometry. this will ensure multi material support

			scope.addGroup( groupStart, groupCount, 0 );

			// calculate new start value for groups

			groupStart += groupCount;

		}

		function generateCap( top:Bool ) {

			// save the index of the first center vertex
			var centerIndexStart = index;

			var uv = new Vector2();
			var vertex = new Vector3();

			var groupCount = 0;

			var radius = ( top ) ? radiusTop : radiusBottom;
			var sign = ( top ) ? 1 : - 1;

			// first we generate the center vertex data of the cap.
			// because the geometry needs one set of uvs per face,
			// we must generate a center vertex per face/segment

			for ( x in 1...radialSegments+1 ) {

				// vertex

				vertices.push( 0, halfHeight * sign, 0 );

				// normal

				normals.push( 0, sign, 0 );

				// uv

				uvs.push( 0.5, 0.5 );

				// increase index

				index ++;

			}

			// save the index of the last center vertex
			var centerIndexEnd = index;

			// now we generate the surrounding vertices, normals and uvs

			for ( x in 0...radialSegments+1 ) {

				var u = x / radialSegments;
				var theta = u * thetaLength + thetaStart;

				var cosTheta = Math.cos( theta );
				var sinTheta = Math.sin( theta );

				// vertex

				vertex.x = radius * sinTheta;
				vertex.y = halfHeight * sign;
				vertex.z = radius * cosTheta;
				vertices.push( vertex.x, vertex.y, vertex.z );

				// normal

				normals.push( 0, sign, 0 );

				// uv

				uv.x = ( cosTheta * 0.5 ) + 0.5;
				uv.y = ( sinTheta * 0.5 * sign ) + 0.5;
				uvs.push( uv.x, uv.y );

				// increase index

				index ++;

			}

			// generate indices

			for ( x in 0...radialSegments ) {

				var c = centerIndexStart + x;
				var i = centerIndexEnd + x;

				if ( top ) {

					// face top

					indices.push( i, i + 1, c );

				} else {

					// face bottom

					indices.push( i + 1, i, c );

				}

				groupCount += 3;

			}

			// add a group to the geometry. this will ensure multi material support

			scope.addGroup( groupStart, groupCount, (top) ? 1 : 2 );

			// calculate new start value for groups

			groupStart += groupCount;

		}

	}

	public function copy( source:CylinderGeometry ) {

		super.copy( source );

		this.parameters = haxe.ds.Object.assign( {}, source.parameters );

		return this;

	}

	static public function fromJSON( data:Dynamic ) {

		return new CylinderGeometry( data.radiusTop, data.radiusBottom, data.height, data.radialSegments, data.heightSegments, data.openEnded, data.thetaStart, data.thetaLength );

	}

}