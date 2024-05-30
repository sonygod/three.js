import three.Vector3;

/**
 * Usage:
 *  var exporter = new STLExporter();
 *
 *  // second argument is a list of options
 *  var data = exporter.parse( mesh, { binary: true } );
 *
 */

class STLExporter {

	public function parse( scene:Dynamic, options:Dynamic = null ) {

		options = {
			binary: false,
			...options
		};

		var binary = options.binary;

		//

		var objects = [];
		var triangles = 0;

		scene.traverse( function ( object ) {

			if ( object.isMesh ) {

				var geometry = object.geometry;

				var index = geometry.index;
				var positionAttribute = geometry.getAttribute( 'position' );

				triangles += ( index !== null ) ? ( index.count / 3 ) : ( positionAttribute.count / 3 );

				objects.push( {
					object3d: object,
					geometry: geometry
				} );

			}

		} );

		var output;
		var offset = 80; // skip header

		if ( binary === true ) {

			var bufferLength = triangles * 2 + triangles * 3 * 4 * 4 + 80 + 4;
			var arrayBuffer = haxe.io.Bytes.alloc(bufferLength);
			output = new haxe.io.BytesOutput(arrayBuffer);
			output.writeInt32(offset, triangles, true); offset += 4;

		} else {

			output = '';
			output += 'solid exported\n';

		}

		var vA = new Vector3();
		var vB = new Vector3();
		var vC = new Vector3();
		var cb = new Vector3();
		var ab = new Vector3();
		var normal = new Vector3();

		for ( i in 0...objects.length ) {

			var object = objects[i].object3d;
			var geometry = objects[i].geometry;

			var index = geometry.index;
			var positionAttribute = geometry.getAttribute( 'position' );

			if ( index !== null ) {

				// indexed geometry

				for ( j in 0...index.count ) {

					var a = index.getX( j + 0 );
					var b = index.getX( j + 1 );
					var c = index.getX( j + 2 );

					writeFace( a, b, c, positionAttribute, object );

				}

			} else {

				// non-indexed geometry

				for ( j in 0...positionAttribute.count ) {

					var a = j + 0;
					var b = j + 1;
					var c = j + 2;

					writeFace( a, b, c, positionAttribute, object );

				}

			}

		}

		if ( binary === false ) {

			output += 'endsolid exported\n';

		}

		return output;

		function writeFace( a:Dynamic, b:Dynamic, c:Dynamic, positionAttribute:Dynamic, object:Dynamic ) {

			vA.fromBufferAttribute( positionAttribute, a );
			vB.fromBufferAttribute( positionAttribute, b );
			vC.fromBufferAttribute( positionAttribute, c );

			if ( object.isSkinnedMesh === true ) {

				object.applyBoneTransform( a, vA );
				object.applyBoneTransform( b, vB );
				object.applyBoneTransform( c, vC );

			}

			vA.applyMatrix4( object.matrixWorld );
			vB.applyMatrix4( object.matrixWorld );
			vC.applyMatrix4( object.matrixWorld );

			writeNormal( vA, vB, vC );

			writeVertex( vA );
			writeVertex( vB );
			writeVertex( vC );

			if ( binary === true ) {

				output.writeInt16(offset, 0, true); offset += 2;

			} else {

				output += '\t\tendloop\n';
				output += '\tendfacet\n';

			}

		}

		function writeNormal( vA:Vector3, vB:Vector3, vC:Vector3 ) {

			cb.subVectors( vC, vB );
			ab.subVectors( vA, vB );
			cb.cross( ab ).normalize();

			normal.copy( cb ).normalize();

			if ( binary === true ) {

				output.writeFloat32(offset, normal.x, true); offset += 4;
				output.writeFloat32(offset, normal.y, true); offset += 4;
				output.writeFloat32(offset, normal.z, true); offset += 4;

			} else {

				output += '\tfacet normal ' + normal.x + ' ' + normal.y + ' ' + normal.z + '\n';
				output += '\t\touter loop\n';

			}

		}

		function writeVertex( vertex:Vector3 ) {

			if ( binary === true ) {

				output.writeFloat32(offset, vertex.x, true); offset += 4;
				output.writeFloat32(offset, vertex.y, true); offset += 4;
				output.writeFloat32(offset, vertex.z, true); offset += 4;

			} else {

				output += '\t\t\tvertex ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z + '\n';

			}

		}

	}

}

export class STLExporter;