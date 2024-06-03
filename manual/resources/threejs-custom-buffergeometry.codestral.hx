import three.*;
import threejsLessonUtils.threejsLessonUtils;

class Main {

	static function main() {

		var loader = new TextureLoader();
		var texture = loader.load( '/manual/examples/resources/images/star-light.png' );
		texture.wrapS = Texture.RepeatWrapping;
		texture.wrapT = Texture.RepeatWrapping;
		texture.repeat.set( 3, 1 );

		function makeMesh( geometry:BufferGeometry ):Mesh {

			var material = new MeshPhongMaterial( {
				color: 0xFF0000,		// HSL color conversion not supported in HaxeThree.js, use hex instead
				side: MaterialSide.DoubleSide,
				map: texture,
			} );
			return new Mesh( geometry, material );

		}

		threejsLessonUtils.addDiagrams( {
			geometryCylinder: {
				create():Object3D {

					return new Object3D();

				},
			},
			bufferGeometryCylinder: {
				create():Mesh {

					var numSegments = 24;
					var positions = [];
					var uvs = [];
					for ( var s:Int = 0; s <= numSegments; ++s ) {

						var u = s / numSegments;
						var a = u * Math.PI * 2;
						var x = Math.sin( a );
						var z = Math.cos( a );
						positions.push( x, -1, z );
						positions.push( x, 1, z );
						uvs.push( u, 0 );
						uvs.push( u, 1 );

					}

					var indices = [];
					for ( var s:Int = 0; s < numSegments; ++s ) {

						var ndx = s * 2;
						indices.push(
							ndx, ndx + 2, ndx + 1,
							ndx + 1, ndx + 2, ndx + 3,
						);

					}

					var positionNumComponents = 3;
					var uvNumComponents = 2;
					var geometry = new BufferGeometry();
					geometry.setAttribute(
						'position',
						new Float32BufferAttribute( positions, positionNumComponents ) );
					geometry.setAttribute(
						'uv',
						new Float32BufferAttribute( uvs, uvNumComponents ) );

					geometry.setIndex( indices );
					geometry.computeVertexNormals();
					geometry.scale( 5, 5, 5 );
					return makeMesh( geometry );

				},
			},
		} );

	}

}