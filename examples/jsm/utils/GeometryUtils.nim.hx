import three.Vector3;

/**
 * Generates 2D-Coordinates in a very fast way.
 *
 * Based on work by:
 * @link http://www.openprocessing.org/sketch/15493
 *
 * @param center     Center of Hilbert curve.
 * @param size       Total width of Hilbert curve.
 * @param iterations Number of subdivisions.
 * @param v0         Corner index -X, -Z.
 * @param v1         Corner index -X, +Z.
 * @param v2         Corner index +X, +Z.
 * @param v3         Corner index +X, -Z.
 */
function hilbert2D( center:Vector3 = new Vector3( 0, 0, 0 ), size:Float = 10, iterations:Int = 1, v0:Int = 0, v1:Int = 1, v2:Int = 2, v3:Int = 3 ) {

	var half:Float = size / 2;

	var vec_s:Array<Vector3> = [
		new Vector3( center.x - half, center.y, center.z - half ),
		new Vector3( center.x - half, center.y, center.z + half ),
		new Vector3( center.x + half, center.y, center.z + half ),
		new Vector3( center.x + half, center.y, center.z - half )
	];

	var vec:Array<Vector3> = [
		vec_s[ v0 ],
		vec_s[ v1 ],
		vec_s[ v2 ],
		vec_s[ v3 ]
	];

	// Recurse iterations
	if ( 0 <= -- iterations ) {

		return [
			...hilbert2D( vec[ 0 ], half, iterations, v0, v3, v2, v1 ),
			...hilbert2D( vec[ 1 ], half, iterations, v0, v1, v2, v3 ),
			...hilbert2D( vec[ 2 ], half, iterations, v0, v1, v2, v3 ),
			...hilbert2D( vec[ 3 ], half, iterations, v2, v1, v0, v3 )
		];

	}

	// Return complete Hilbert Curve.
	return vec;

}

/**
 * Generates 3D-Coordinates in a very fast way.
 *
 * Based on work by:
 * @link https://openprocessing.org/user/5654
 *
 * @param center     Center of Hilbert curve.
 * @param size       Total width of Hilbert curve.
 * @param iterations Number of subdivisions.
 * @param v0         Corner index -X, +Y, -Z.
 * @param v1         Corner index -X, +Y, +Z.
 * @param v2         Corner index -X, -Y, +Z.
 * @param v3         Corner index -X, -Y, -Z.
 * @param v4         Corner index +X, -Y, -Z.
 * @param v5         Corner index +X, -Y, +Z.
 * @param v6         Corner index +X, +Y, +Z.
 * @param v7         Corner index +X, +Y, -Z.
 */
function hilbert3D( center:Vector3 = new Vector3( 0, 0, 0 ), size:Float = 10, iterations:Int = 1, v0:Int = 0, v1:Int = 1, v2:Int = 2, v3:Int = 3, v4:Int = 4, v5:Int = 5, v6:Int = 6, v7:Int = 7 ) {

	// Default Vars
	var half:Float = size / 2;

	var vec_s:Array<Vector3> = [
		new Vector3( center.x - half, center.y + half, center.z - half ),
		new Vector3( center.x - half, center.y + half, center.z + half ),
		new Vector3( center.x - half, center.y - half, center.z + half ),
		new Vector3( center.x - half, center.y - half, center.z - half ),
		new Vector3( center.x + half, center.y - half, center.z - half ),
		new Vector3( center.x + half, center.y - half, center.z + half ),
		new Vector3( center.x + half, center.y + half, center.z + half ),
		new Vector3( center.x + half, center.y + half, center.z - half )
	];

	var vec:Array<Vector3> = [
		vec_s[ v0 ],
		vec_s[ v1 ],
		vec_s[ v2 ],
		vec_s[ v3 ],
		vec_s[ v4 ],
		vec_s[ v5 ],
		vec_s[ v6 ],
		vec_s[ v7 ]
	];

	// Recurse iterations
	if ( -- iterations >= 0 ) {

		return [
			...hilbert3D( vec[ 0 ], half, iterations, v0, v3, v4, v7, v6, v5, v2, v1 ),
			...hilbert3D( vec[ 1 ], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3 ),
			...hilbert3D( vec[ 2 ], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3 ),
			...hilbert3D( vec[ 3 ], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5 ),
			...hilbert3D( vec[ 4 ], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5 ),
			...hilbert3D( vec[ 5 ], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7 ),
			...hilbert3D( vec[ 6 ], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7 ),
			...hilbert3D( vec[ 7 ], half, iterations, v6, v5, v2, v1, v0, v3, v4, v7 )
		];

	}

	// Return complete Hilbert Curve.
	return vec;

}

/**
 * Generates a Gosper curve (lying in the XY plane)
 *
 * https://gist.github.com/nitaku/6521802
 *
 * @param size The size of a single gosper island.
 */
function gosper( size:Float = 1 ) {

	function fractalize( config ) {

		var output;
		var input = config.axiom;

		for ( var i:Int = 0, il = config.steps; 0 <= il ? i < il : i > il; 0 <= il ? i ++ : i -- ) {

			output = '';

			for ( var j:Int = 0, jl = input.length; j < jl; j ++ ) {

				var char = input[ j ];

				if ( char in config.rules ) {

					output += config.rules[ char ];

				} else {

					output += char;

				}

			}

			input = output;

		}

		return output;

	}

	function toPoints( config ) {

		var currX:Float = 0, currY:Float = 0;
		var angle:Float = 0;
		var path:Array<Float> = [ 0, 0, 0 ];
		var fractal = config.fractal;

		for ( var i:Int = 0, l = fractal.length; i < l; i ++ ) {

			var char = fractal[ i ];

			if ( char === '+' ) {

				angle += config.angle;

			} else if ( char === '-' ) {

				angle -= config.angle;

			} else if ( char === 'F' ) {

				currX += config.size * Math.cos( angle );
				currY += - config.size * Math.sin( angle );
				path.push( currX, currY, 0 );

			}

		}

		return path;

	}

	//

	var gosper = fractalize( {
		axiom: 'A',
		steps: 4,
		rules: {
			A: 'A+BF++BF-FA--FAFA-BF+',
			B: '-FA+BFBF++BF+FA--FA-B'
		}
	} );

	var points = toPoints( {
		fractal: gosper,
		size: size,
		angle: Math.PI / 3 // 60 degrees
	} );

	return points;

}