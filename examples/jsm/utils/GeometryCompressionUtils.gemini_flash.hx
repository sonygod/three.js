import three.extras.core.BufferAttribute;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Vector3;
import three.materials.PackedPhongMaterial;

/**
 * Octahedron and Quantization encodings based on work by:
 *
 * @link https://github.com/tsherif/mesh-quantization-example
 *
 */
class NormalCompression {

	/**
	 * Make the input mesh.geometry's normal attribute encoded and compressed by 3 different methods.
	 * Also will change the mesh.material to `PackedPhongMaterial` which let the vertex shader program decode the normal data.
	 *
	 * @param {three.Mesh} mesh
	 * @param {String} encodeMethod		"DEFAULT" || "OCT1Byte" || "OCT2Byte" || "ANGLES"
	 *
	 */
	public static function compressNormals( mesh:three.Mesh, encodeMethod:String ):Void {

		if ( ! mesh.geometry ) {

			console.error( 'Mesh must contain geometry. ' );

		}

		var normal = mesh.geometry.attributes.normal;

		if ( ! normal ) {

			console.error( 'Geometry must contain normal attribute. ' );

		}

		if ( normal.isPacked ) return;

		if ( normal.itemSize != 3 ) {

			console.error( 'normal.itemSize is not 3, which cannot be encoded. ' );

		}

		var array = normal.array;
		var count = normal.count;

		var result:Dynamic;
		if ( encodeMethod == 'DEFAULT' ) {

			// TODO: Add 1 byte to the result, making the encoded length to be 4 bytes.
			result = new Uint8Array( count * 3 );

			for ( var idx:Int = 0; idx < array.length; idx += 3 ) {

				var encoded = defaultEncode( array[ idx ], array[ idx + 1 ], array[ idx + 2 ], 1 );

				result[ idx + 0 ] = encoded[ 0 ];
				result[ idx + 1 ] = encoded[ 1 ];
				result[ idx + 2 ] = encoded[ 2 ];

			}

			mesh.geometry.setAttribute( 'normal', new BufferAttribute( result, 3, true ) );
			mesh.geometry.attributes.normal.bytes = result.length * 1;

		} else if ( encodeMethod == 'OCT1Byte' ) {

			/**
			* It is not recommended to use 1-byte octahedron normals encoding unless you want to extremely reduce the memory usage
			* As it makes vertex data not aligned to a 4 byte boundary which may harm some WebGL implementations and sometimes the normal distortion is visible
			* Please refer to @zeux 's comments in https://github.com/mrdoob/three.js/pull/18208
			*/

			result = new Int8Array( count * 2 );

			for ( var idx:Int = 0; idx < array.length; idx += 3 ) {

				var encoded = octEncodeBest( array[ idx ], array[ idx + 1 ], array[ idx + 2 ], 1 );

				result[ idx / 3 * 2 + 0 ] = encoded[ 0 ];
				result[ idx / 3 * 2 + 1 ] = encoded[ 1 ];

			}

			mesh.geometry.setAttribute( 'normal', new BufferAttribute( result, 2, true ) );
			mesh.geometry.attributes.normal.bytes = result.length * 1;

		} else if ( encodeMethod == 'OCT2Byte' ) {

			result = new Int16Array( count * 2 );

			for ( var idx:Int = 0; idx < array.length; idx += 3 ) {

				var encoded = octEncodeBest( array[ idx ], array[ idx + 1 ], array[ idx + 2 ], 2 );

				result[ idx / 3 * 2 + 0 ] = encoded[ 0 ];
				result[ idx / 3 * 2 + 1 ] = encoded[ 1 ];

			}

			mesh.geometry.setAttribute( 'normal', new BufferAttribute( result, 2, true ) );
			mesh.geometry.attributes.normal.bytes = result.length * 2;

		} else if ( encodeMethod == 'ANGLES' ) {

			result = new Uint16Array( count * 2 );

			for ( var idx:Int = 0; idx < array.length; idx += 3 ) {

				var encoded = anglesEncode( array[ idx ], array[ idx + 1 ], array[ idx + 2 ] );

				result[ idx / 3 * 2 + 0 ] = encoded[ 0 ];
				result[ idx / 3 * 2 + 1 ] = encoded[ 1 ];

			}

			mesh.geometry.setAttribute( 'normal', new BufferAttribute( result, 2, true ) );
			mesh.geometry.attributes.normal.bytes = result.length * 2;

		} else {

			console.error( 'Unrecognized encoding method, should be `DEFAULT` or `ANGLES` or `OCT`. ' );

		}

		mesh.geometry.attributes.normal.needsUpdate = true;
		mesh.geometry.attributes.normal.isPacked = true;
		mesh.geometry.attributes.normal.packingMethod = encodeMethod;

		// modify material
		if ( ! ( mesh.material is PackedPhongMaterial ) ) {

			mesh.material = new PackedPhongMaterial().copy( mesh.material );

		}

		if ( encodeMethod == 'ANGLES' ) {

			mesh.material.defines.USE_PACKED_NORMAL = 0;

		}

		if ( encodeMethod == 'OCT1Byte' ) {

			mesh.material.defines.USE_PACKED_NORMAL = 1;

		}

		if ( encodeMethod == 'OCT2Byte' ) {

			mesh.material.defines.USE_PACKED_NORMAL = 1;

		}

		if ( encodeMethod == 'DEFAULT' ) {

			mesh.material.defines.USE_PACKED_NORMAL = 2;

		}

	}


	/**
		 * Make the input mesh.geometry's position attribute encoded and compressed.
		 * Also will change the mesh.material to `PackedPhongMaterial` which let the vertex shader program decode the position data.
		 *
		 * @param {three.Mesh} mesh
		 *
		 */
	public static function compressPositions( mesh:three.Mesh ):Void {

		if ( ! mesh.geometry ) {

			console.error( 'Mesh must contain geometry. ' );

		}

		var position = mesh.geometry.attributes.position;

		if ( ! position ) {

			console.error( 'Geometry must contain position attribute. ' );

		}

		if ( position.isPacked ) return;

		if ( position.itemSize != 3 ) {

			console.error( 'position.itemSize is not 3, which cannot be packed. ' );

		}

		var array = position.array;
		var encodingBytes:Int = 2;

		var result = quantizedEncode( array, encodingBytes );

		var quantized = result.quantized;
		var decodeMat = result.decodeMat;

		// IMPORTANT: calculate original geometry bounding info first, before updating packed positions
		if ( mesh.geometry.boundingBox == null ) mesh.geometry.computeBoundingBox();
		if ( mesh.geometry.boundingSphere == null ) mesh.geometry.computeBoundingSphere();

		mesh.geometry.setAttribute( 'position', new BufferAttribute( quantized, 3 ) );
		mesh.geometry.attributes.position.isPacked = true;
		mesh.geometry.attributes.position.needsUpdate = true;
		mesh.geometry.attributes.position.bytes = quantized.length * encodingBytes;

		// modify material
		if ( ! ( mesh.material is PackedPhongMaterial ) ) {

			mesh.material = new PackedPhongMaterial().copy( mesh.material );

		}

		mesh.material.defines.USE_PACKED_POSITION = 0;

		mesh.material.uniforms.quantizeMatPos.value = decodeMat;
		mesh.material.uniforms.quantizeMatPos.needsUpdate = true;

	}

	/**
	 * Make the input mesh.geometry's uv attribute encoded and compressed.
	 * Also will change the mesh.material to `PackedPhongMaterial` which let the vertex shader program decode the uv data.
	 *
	 * @param {three.Mesh} mesh
	 *
	 */
	public static function compressUvs( mesh:three.Mesh ):Void {

		if ( ! mesh.geometry ) {

			console.error( 'Mesh must contain geometry property. ' );

		}

		var uvs = mesh.geometry.attributes.uv;

		if ( ! uvs ) {

			console.error( 'Geometry must contain uv attribute. ' );

		}

		if ( uvs.isPacked ) return;

		var range = { min: Infinity, max: - Infinity };

		var array = uvs.array;

		for ( var i:Int = 0; i < array.length; i ++ ) {

			range.min = Math.min( range.min, array[ i ] );
			range.max = Math.max( range.max, array[ i ] );

		}

		var result:Dynamic;

		if ( range.min >= - 1.0 && range.max <= 1.0 ) {

			// use default encoding method
			result = new Uint16Array( array.length );

			for ( var i:Int = 0; i < array.length; i += 2 ) {

				var encoded = defaultEncode( array[ i ], array[ i + 1 ], 0, 2 );

				result[ i ] = encoded[ 0 ];
				result[ i + 1 ] = encoded[ 1 ];

			}

			mesh.geometry.setAttribute( 'uv', new BufferAttribute( result, 2, true ) );
			mesh.geometry.attributes.uv.isPacked = true;
			mesh.geometry.attributes.uv.needsUpdate = true;
			mesh.geometry.attributes.uv.bytes = result.length * 2;

			if ( ! ( mesh.material is PackedPhongMaterial ) ) {

				mesh.material = new PackedPhongMaterial().copy( mesh.material );

			}

			mesh.material.defines.USE_PACKED_UV = 0;

		} else {

			// use quantized encoding method
			result = quantizedEncodeUV( array, 2 );

			mesh.geometry.setAttribute( 'uv', new BufferAttribute( result.quantized, 2 ) );
			mesh.geometry.attributes.uv.isPacked = true;
			mesh.geometry.attributes.uv.needsUpdate = true;
			mesh.geometry.attributes.uv.bytes = result.quantized.length * 2;

			if ( ! ( mesh.material is PackedPhongMaterial ) ) {

				mesh.material = new PackedPhongMaterial().copy( mesh.material );

			}

			mesh.material.defines.USE_PACKED_UV = 1;

			mesh.material.uniforms.quantizeMatUV.value = result.decodeMat;
			mesh.material.uniforms.quantizeMatUV.needsUpdate = true;

		}

	}


	// Encoding functions

	static function defaultEncode( x:Float, y:Float, z:Float, bytes:Int ):Array<Int> {

		if ( bytes == 1 ) {

			var tmpx:Int = Math.round( ( x + 1 ) * 0.5 * 255 );
			var tmpy:Int = Math.round( ( y + 1 ) * 0.5 * 255 );
			var tmpz:Int = Math.round( ( z + 1 ) * 0.5 * 255 );
			return [ tmpx, tmpy, tmpz ];

		} else if ( bytes == 2 ) {

			var tmpx:Int = Math.round( ( x + 1 ) * 0.5 * 65535 );
			var tmpy:Int = Math.round( ( y + 1 ) * 0.5 * 65535 );
			var tmpz:Int = Math.round( ( z + 1 ) * 0.5 * 65535 );
			return [ tmpx, tmpy, tmpz ];

		} else {

			console.error( 'number of bytes must be 1 or 2' );

		}

	}

	// for `Angles` encoding
	static function anglesEncode( x:Float, y:Float, z:Float ):Array<Int> {

		var normal0:Int = Std.int( 0.5 * ( 1.0 + Math.atan2( y, x ) / Math.PI ) * 65535 );
		var normal1:Int = Std.int( 0.5 * ( 1.0 + z ) * 65535 );
		return [ normal0, normal1 ];

	}

	// for `Octahedron` encoding
	static function octEncodeBest( x:Float, y:Float, z:Float, bytes:Int ):Array<Int> {

		var oct:Array<Int>, dec:Array<Float>, best:Array<Int>, currentCos:Float, bestCos:Float;

		// Test various combinations of ceil and floor
		// to minimize rounding errors
		best = oct = octEncodeVec3( x, y, z, 'floor', 'floor' );
		dec = octDecodeVec2( oct );
		bestCos = dot( x, y, z, dec );

		oct = octEncodeVec3( x, y, z, 'ceil', 'floor' );
		dec = octDecodeVec2( oct );
		currentCos = dot( x, y, z, dec );

		if ( currentCos > bestCos ) {

			best = oct;
			bestCos = currentCos;

		}

		oct = octEncodeVec3( x, y, z, 'floor', 'ceil' );
		dec = octDecodeVec2( oct );
		currentCos = dot( x, y, z, dec );

		if ( currentCos > bestCos ) {

			best = oct;
			bestCos = currentCos;

		}

		oct = octEncodeVec3( x, y, z, 'ceil', 'ceil' );
		dec = octDecodeVec2( oct );
		currentCos = dot( x, y, z, dec );

		if ( currentCos > bestCos ) {

			best = oct;

		}

		return best;

		function octEncodeVec3( x0:Float, y0:Float, z0:Float, xfunc:String, yfunc:String ):Array<Int> {

			var x:Float = x0 / ( Math.abs( x0 ) + Math.abs( y0 ) + Math.abs( z0 ) );
			var y:Float = y0 / ( Math.abs( x0 ) + Math.abs( y0 ) + Math.abs( z0 ) );

			if ( z < 0 ) {

				var tempx = ( 1 - Math.abs( y ) ) * ( x >= 0 ? 1 : - 1 );
				var tempy = ( 1 - Math.abs( x ) ) * ( y >= 0 ? 1 : - 1 );

				x = tempx;
				y = tempy;

				var diff:Float = 1 - Math.abs( x ) - Math.abs( y );
				if ( diff > 0 ) {

					diff += 0.001;
					x += x > 0 ? diff / 2 : - diff / 2;
					y += y > 0 ? diff / 2 : - diff / 2;

				}

			}

			if ( bytes == 1 ) {

				return [
					Std.int( Math.floor( x * 127.5 + ( x < 0 ? 1 : 0 ) ) ),
					Std.int( Math.floor( y * 127.5 + ( y < 0 ? 1 : 0 ) ) )
				];

			}

			if ( bytes == 2 ) {

				return [
					Std.int( Math.floor( x * 32767.5 + ( x < 0 ? 1 : 0 ) ) ),
					Std.int( Math.floor( y * 32767.5 + ( y < 0 ? 1 : 0 ) ) )
				];

			}


		}

		function octDecodeVec2( oct:Array<Int> ):Array<Float> {

			var x:Float = oct[ 0 ];
			var y:Float = oct[ 1 ];

			if ( bytes == 1 ) {

				x /= x < 0 ? 127 : 128;
				y /= y < 0 ? 127 : 128;

			} else if ( bytes == 2 ) {

				x /= x < 0 ? 32767 : 32768;
				y /= y < 0 ? 32767 : 32768;

			}


			var z:Float = 1 - Math.abs( x ) - Math.abs( y );

			if ( z < 0 ) {

				var tmpx:Float = x;
				x = ( 1 - Math.abs( y ) ) * ( x >= 0 ? 1 : - 1 );
				y = ( 1 - Math.abs( tmpx ) ) * ( y >= 0 ? 1 : - 1 );

			}

			var length:Float = Math.sqrt( x * x + y * y + z * z );

			return [
				x / length,
				y / length,
				z / length
			];

		}

		function dot( x:Float, y:Float, z:Float, vec3:Array<Float> ):Float {

			return x * vec3[ 0 ] + y * vec3[ 1 ] + z * vec3[ 2 ];

		}

	}

	static function quantizedEncode( array:Array<Float>, bytes:Int ):{ quantized:Array<Int>, decodeMat:Matrix4 } {

		var quantized:Array<Int>, segments:Int;

		if ( bytes == 1 ) {

			quantized = new Uint8Array( array.length );
			segments = 255;

		} else if ( bytes == 2 ) {

			quantized = new Uint16Array( array.length );
			segments = 65535;

		} else {

			console.error( 'number of bytes error! ' );

		}

		var decodeMat = new Matrix4();

		var min = new Float32Array( 3 );
		var max = new Float32Array( 3 );

		min[ 0 ] = min[ 1 ] = min[ 2 ] = Number.MAX_VALUE;
		max[ 0 ] = max[ 1 ] = max[ 2 ] = - Number.MAX_VALUE;

		for ( var i:Int = 0; i < array.length; i += 3 ) {

			min[ 0 ] = Math.min( min[ 0 ], array[ i + 0 ] );
			min[ 1 ] = Math.min( min[ 1 ], array[ i + 1 ] );
			min[ 2 ] = Math.min( min[ 2 ], array[ i + 2 ] );
			max[ 0 ] = Math.max( max[ 0 ], array[ i + 0 ] );
			max[ 1 ] = Math.max( max[ 1 ], array[ i + 1 ] );
			max[ 2 ] = Math.max( max[ 2 ], array[ i + 2 ] );

		}

		decodeMat.scale( new Vector3(
			( max[ 0 ] - min[ 0 ] ) / segments,
			( max[ 1 ] - min[ 1 ] ) / segments,
			( max[ 2 ] - min[ 2 ] ) / segments
		) );

		decodeMat.elements[ 12 ] = min[ 0 ];
		decodeMat.elements[ 13 ] = min[ 1 ];
		decodeMat.elements[ 14 ] = min[ 2 ];

		decodeMat.transpose();


		var multiplier = new Float32Array( [
			max[ 0 ] !== min[ 0 ] ? segments / ( max[ 0 ] - min[ 0 ] ) : 0,
			max[ 1 ] !== min[ 1 ] ? segments / ( max[ 1 ] - min[ 1 ] ) : 0,
			max[ 2 ] !== min[ 2 ] ? segments / ( max[ 2 ] - min[ 2 ] ) : 0
		] );

		for ( var i:Int = 0; i < array.length; i += 3 ) {

			quantized[ i + 0 ] = Std.int( Math.floor( ( array[ i + 0 ] - min[ 0 ] ) * multiplier[ 0 ] ) );
			quantized[ i + 1 ] = Std.int( Math.floor( ( array[ i + 1 ] - min[ 1 ] ) * multiplier[ 1 ] ) );
			quantized[ i + 2 ] = Std.int( Math.floor( ( array[ i + 2 ] - min[ 2 ] ) * multiplier[ 2 ] ) );

		}

		return {
			quantized: quantized,
			decodeMat: decodeMat
		};

	}

	static function quantizedEncodeUV( array:Array<Float>, bytes:Int ):{ quantized:Array<Int>, decodeMat:Matrix3 } {

		var quantized:Array<Int>, segments:Int;

		if ( bytes == 1 ) {

			quantized = new Uint8Array( array.length );
			segments = 255;

		} else if ( bytes == 2 ) {

			quantized = new Uint16Array( array.length );
			segments = 65535;

		} else {

			console.error( 'number of bytes error! ' );

		}

		var decodeMat = new Matrix3();

		var min = new Float32Array( 2 );
		var max = new Float32Array( 2 );

		min[ 0 ] = min[ 1 ] = Number.MAX_VALUE;
		max[ 0 ] = max[ 1 ] = - Number.MAX_VALUE;

		for ( var i:Int = 0; i < array.length; i += 2 ) {

			min[ 0 ] = Math.min( min[ 0 ], array[ i + 0 ] );
			min[ 1 ] = Math.min( min[ 1 ], array[ i + 1 ] );
			max[ 0 ] = Math.max( max[ 0 ], array[ i + 0 ] );
			max[ 1 ] = Math.max( max[ 1 ], array[ i + 1 ] );

		}

		decodeMat.scale(
			( max[ 0 ] - min[ 0 ] ) / segments,
			( max[ 1 ] - min[ 1 ] ) / segments
		);

		decodeMat.elements[ 6 ] = min[ 0 ];
		decodeMat.elements[ 7 ] = min[ 1 ];

		decodeMat.transpose();

		var multiplier = new Float32Array( [
			max[ 0 ] !== min[ 0 ] ? segments / ( max[ 0 ] - min[ 0 ] ) : 0,
			max[ 1 ] !== min[ 1 ] ? segments / ( max[ 1 ] - min[ 1 ] ) : 0
		] );

		for ( var i:Int = 0; i < array.length; i += 2 ) {

			quantized[ i + 0 ] = Std.int( Math.floor( ( array[ i + 0 ] - min[ 0 ] ) * multiplier[ 0 ] ) );
			quantized[ i + 1 ] = Std.int( Math.floor( ( array[ i + 1 ] - min[ 1 ] ) * multiplier[ 1 ] ) );

		}

		return {
			quantized: quantized,
			decodeMat: decodeMat
		};

	}



}