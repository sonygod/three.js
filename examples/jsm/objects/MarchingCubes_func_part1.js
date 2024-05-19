import {
	BufferAttribute,
	BufferGeometry,
	Color,
	DynamicDrawUsage,
	Mesh,
	Sphere,
	Vector3
} from 'three';

/**
 * Port of http://webglsamples.org/blob/blob.html
 */


constructor( resolution, material, enableUvs = false, enableColors = false, maxPolyCount = 10000 ) {

		const geometry = new BufferGeometry();

		super( geometry, material );

		this.isMarchingCubes = true;

		const scope = this;

		// temp buffers used in polygonize

		const vlist = new Float32Array( 12 * 3 );
		const nlist = new Float32Array( 12 * 3 );
		const clist = new Float32Array( 12 * 3 );

		this.enableUvs = enableUvs;
		this.enableColors = enableColors;

		// functions have to be object properties
		// prototype functions kill performance
		// (tested and it was 4x slower !!!)

		this.init = function ( resolution ) {

			this.resolution = resolution;

			// parameters

			this.isolation = 80.0;

			// size of field, 32 is pushing it in Javascript :)

			this.size = resolution;
			this.size2 = this.size * this.size;
			this.size3 = this.size2 * this.size;
			this.halfsize = this.size / 2.0;

			// deltas

			this.delta = 2.0 / this.size;
			this.yd = this.size;
			this.zd = this.size2;

			this.field = new Float32Array( this.size3 );
			this.normal_cache = new Float32Array( this.size3 * 3 );
			this.palette = new Float32Array( this.size3 * 3 );

			//

			this.count = 0;

			const maxVertexCount = maxPolyCount * 3;

			this.positionArray = new Float32Array( maxVertexCount * 3 );
			const positionAttribute = new BufferAttribute( this.positionArray, 3 );
			positionAttribute.setUsage( DynamicDrawUsage );
			geometry.setAttribute( 'position', positionAttribute );

			this.normalArray = new Float32Array( maxVertexCount * 3 );
			const normalAttribute = new BufferAttribute( this.normalArray, 3 );
			normalAttribute.setUsage( DynamicDrawUsage );
			geometry.setAttribute( 'normal', normalAttribute );

			if ( this.enableUvs ) {

				this.uvArray = new Float32Array( maxVertexCount * 2 );
				const uvAttribute = new BufferAttribute( this.uvArray, 2 );
				uvAttribute.setUsage( DynamicDrawUsage );
				geometry.setAttribute( 'uv', uvAttribute );

			}

			if ( this.enableColors ) {

				this.colorArray = new Float32Array( maxVertexCount * 3 );
				const colorAttribute = new BufferAttribute( this.colorArray, 3 );
				colorAttribute.setUsage( DynamicDrawUsage );
				geometry.setAttribute( 'color', colorAttribute );

			}

			geometry.boundingSphere = new Sphere( new Vector3(), 1 );

		};

		///////////////////////
		// Polygonization
		///////////////////////

		function lerp( a, b, t ) {

			return a + ( b - a ) * t;

		}

		function VIntX( q, offset, isol, x, y, z, valp1, valp2, c_offset1, c_offset2 ) {

			const mu = ( isol - valp1 ) / ( valp2 - valp1 ),
				nc = scope.normal_cache;

			vlist[ offset + 0 ] = x + mu * scope.delta;
			vlist[ offset + 1 ] = y;
			vlist[ offset + 2 ] = z;

			nlist[ offset + 0 ] = lerp( nc[ q + 0 ], nc[ q + 3 ], mu );
			nlist[ offset + 1 ] = lerp( nc[ q + 1 ], nc[ q + 4 ], mu );
			nlist[ offset + 2 ] = lerp( nc[ q + 2 ], nc[ q + 5 ], mu );

			clist[ offset + 0 ] = lerp( scope.palette[ c_offset1 * 3 + 0 ], scope.palette[ c_offset2 * 3 + 0 ], mu );
			clist[ offset + 1 ] = lerp( scope.palette[ c_offset1 * 3 + 1 ], scope.palette[ c_offset2 * 3 + 1 ], mu );
			clist[ offset + 2 ] = lerp( scope.palette[ c_offset1 * 3 + 2 ], scope.palette[ c_offset2 * 3 + 2 ], mu );

		}

		function VIntY( q, offset, isol, x, y, z, valp1, valp2, c_offset1, c_offset2 ) {

			const mu = ( isol - valp1 ) / ( valp2 - valp1 ),
				nc = scope.normal_cache;

			vlist[ offset + 0 ] = x;
			vlist[ offset + 1 ] = y + mu * scope.delta;
			vlist[ offset + 2 ] = z;

			const q2 = q + scope.yd * 3;

			nlist[ offset + 0 ] = lerp( nc[ q + 0 ], nc[ q2 + 0 ], mu );
			nlist[ offset + 1 ] = lerp( nc[ q + 1 ], nc[ q2 + 1 ], mu );
			nlist[ offset + 2 ] = lerp( nc[ q + 2 ], nc[ q2 + 2 ], mu );

			clist[ offset + 0 ] = lerp( scope.palette[ c_offset1 * 3 + 0 ], scope.palette[ c_offset2 * 3 + 0 ], mu );
			clist[ offset + 1 ] = lerp( scope.palette[ c_offset1 * 3 + 1 ], scope.palette[ c_offset2 * 3 + 1 ], mu );
			clist[ offset + 2 ] = lerp( scope.palette[ c_offset1 * 3 + 2 ], scope.palette[ c_offset2 * 3 + 2 ], mu );

		}

		function VIntZ( q, offset, isol, x, y, z, valp1, valp2, c_offset1, c_offset2 ) {

			const mu = ( isol - valp1 ) / ( valp2 - valp1 ),
				nc = scope.normal_cache;

			vlist[ offset + 0 ] = x;
			vlist[ offset + 1 ] = y;
			vlist[ offset + 2 ] = z + mu * scope.delta;

			const q2 = q + scope.zd * 3;

			nlist[ offset + 0 ] = lerp( nc[ q + 0 ], nc[ q2 + 0 ], mu );
			nlist[ offset + 1 ] = lerp( nc[ q + 1 ], nc[ q2 + 1 ], mu );
			nlist[ offset + 2 ] = lerp( nc[ q + 2 ], nc[ q2 + 2 ], mu );

			clist[ offset + 0 ] = lerp( scope.palette[ c_offset1 * 3 + 0 ], scope.palette[ c_offset2 * 3 + 0 ], mu );
			clist[ offset + 1 ] = lerp( scope.palette[ c_offset1 * 3 + 1 ], scope.palette[ c_offset2 * 3 + 1 ], mu );
			clist[ offset + 2 ] = lerp( scope.palette[ c_offset1 * 3 + 2 ], scope.palette[ c_offset2 * 3 + 2 ], mu );

		}

		function compNorm( q ) {

			const q3 = q * 3;

			if ( scope.normal_cache[ q3 ] === 0.0 ) {

				scope.normal_cache[ q3 + 0 ] = scope.field[ q - 1 ] - scope.field[ q + 1 ];
				scope.normal_cache[ q3 + 1 ] =
					scope.field[ q - scope.yd ] - scope.field[ q + scope.yd ];
				scope.normal_cache[ q3 + 2 ] =
					scope.field[ q - scope.zd ] - scope.field[ q + scope.zd ];

			}

		}

		// Returns total number of triangles. Fills triangles.
		// (this is where most of time is spent - it's inner work of O(n3) loop )

		function polygonize( fx, fy, fz, q, isol ) {

			// cache indices
			const q1 = q + 1,
				qy = q + scope.yd,
				qz = q + scope.zd,
				q1y = q1 + scope.yd,
				q1z = q1 + scope.zd,
				qyz = q + scope.yd + scope.zd,
				q1yz = q1 + scope.yd + scope.zd;

			let cubeindex = 0;
			const field0 = scope.field[ q ],
				field1 = scope.field[ q1 ],
				field2 = scope.field[ qy ],
				field3 = scope.field[ q1y ],
				field4 = scope.field[ qz ],
				field5 = scope.field[ q1z ],
				field6 = scope.field[ qyz ],
				field7 = scope.field[ q1yz ];

			if ( field0 < isol ) cubeindex |= 1;
			if ( field1 < isol ) cubeindex |= 2;
			if ( field2 < isol ) cubeindex |= 8;
			if ( field3 < isol ) cubeindex |= 4;
			if ( field4 < isol ) cubeindex |= 16;
			if ( field5 < isol ) cubeindex |= 32;
			if ( field6 < isol ) cubeindex |= 128;
			if ( field7 < isol ) cubeindex |= 64;

			// if cube is entirely in/out of the surface - bail, nothing to draw

			const bits = edgeTable[ cubeindex ];
			if ( bits === 0 ) return 0;

			const d = scope.delta,
				fx2 = fx + d,
				fy2 = fy + d,
				fz2 = fz + d;

			// top of the cube

			if ( bits & 1 ) {

				compNorm( q );
				compNorm( q1 );
				VIntX( q * 3, 0, isol, fx, fy, fz, field0, field1, q, q1 );

			}

			if ( bits & 2 ) {

				compNorm( q1 );
				compNorm( q1y );
				VIntY( q1 * 3, 3, isol, fx2, fy, fz, field1, field3, q1, q1y );

			}

			if ( bits & 4 ) {

				compNorm( qy );
				compNorm( q1y );
				VIntX( qy * 3, 6, isol, fx, fy2, fz, field2, field3, qy, q1y );

			}

			if ( bits & 8 ) {

				compNorm( q );
				compNorm( qy );
				VIntY( q * 3, 9, isol, fx, fy, fz, field0, field2, q, qy );

			}

			// bottom of the cube

			if ( bits & 16 ) {

				compNorm( qz );
				compNorm( q1z );
				VIntX( qz * 3, 12, isol, fx, fy, fz2, field4, field5, qz, q1z );

			}

			if ( bits & 32 ) {

				compNorm( q1z );
				compNorm( q1yz );
				VIntY(
					q1z * 3,
					15,
					isol,
					fx2,
					fy,
					fz2,
					field5,
					field7,
					q1z,
					q1yz
				);

			}

			if ( bits & 64 ) {

				compNorm( qyz );
				compNorm( q1yz );
				VIntX(
					qyz * 3,
					18,
					isol,
					fx,
					fy2,
					fz2,
					field6,
					field7,
					qyz,
					q1yz
				);

			}

			if ( bits & 128 ) {

				compNorm( qz );
				compNorm( qyz );
				VIntY( qz * 3, 21, isol, fx, fy, fz2, field4, field6, qz, qyz );

			}

			// vertical lines of the cube
			if ( bits & 256 ) {

				compNorm( q );
				compNorm( qz );
				VIntZ( q * 3, 24, isol, fx, fy, fz, field0, field4, q, qz );

			}

			if ( bits & 512 ) {

				compNorm( q1 );
				compNorm( q1z );
				VIntZ( q1 * 3, 27, isol, fx2, fy, fz, field1, field5, q1, q1z );

			}

			if ( bits & 1024 ) {

				compNorm( q1y );
				compNorm( q1yz );
				VIntZ(
					q1y * 3,
					30,
					isol,
					fx2,
					fy2,
					fz,
					field3,
					field7,
					q1y,
					q1yz
				);

			}

			if ( bits & 2048 ) {

				compNorm( qy );
				compNorm( qyz );
				VIntZ( qy * 3, 33, isol, fx, fy2, fz, field2, field6, qy, qyz );

			}

			cubeindex <<= 4; // re-purpose cubeindex into an offset into triTable

			let o1,
				o2,
				o3,
				numtris = 0,
				i = 0;

			// here is where triangles are created

			while ( triTable[ cubeindex + i ] != - 1 ) {

				o1 = cubeindex + i;
				o2 = o1 + 1;
				o3 = o1 + 2;

				posnormtriv(
					vlist,
					nlist,
					clist,
					3 * triTable[ o1 ],
					3 * triTable[ o2 ],
					3 * triTable[ o3 ]
				);

				i += 3;
				numtris ++;

			}

			return numtris;

		}

		function posnormtriv( pos, norm, colors, o1, o2, o3 ) {

			const c = scope.count * 3;

			// positions

			scope.positionArray[ c + 0 ] = pos[ o1 ];
			scope.positionArray[ c + 1 ] = pos[ o1 + 1 ];
			scope.positionArray[ c + 2 ] = pos[ o1 + 2 ];

			scope.positionArray[ c + 3 ] = pos[ o2 ];
			scope.positionArray[ c + 4 ] = pos[ o2 + 1 ];
			scope.positionArray[ c + 5 ] = pos[ o2 + 2 ];

			scope.positionArray[ c + 6 ] = pos[ o3 ];
			scope.positionArray[ c + 7 ] = pos[ o3 + 1 ];
			scope.positionArray[ c + 8 ] = pos[ o3 + 2 ];

			// normals

			if ( scope.material.flatShading === true ) {

				const nx = ( norm[ o1 + 0 ] + norm[ o2 + 0 ] + norm[ o3 + 0 ] ) / 3;
				const ny = ( norm[ o1 + 1 ] + norm[ o2 + 1 ] + norm[ o3 + 1 ] ) / 3;
				const nz = ( norm[ o1 + 2 ] + norm[ o2 + 2 ] + norm[ o3 + 2 ] ) / 3;

				scope.normalArray[ c + 0 ] = nx;
				scope.normalArray[ c + 1 ] = ny;
				scope.normalArray[ c + 2 ] = nz;

				scope.normalArray[ c + 3 ] = nx;
				scope.normalArray[ c + 4 ] = ny;
				scope.normalArray[ c + 5 ] = nz;

				scope.normalArray[ c + 6 ] = nx;
				scope.normalArray[ c + 7 ] = ny;
				scope.normalArray[ c + 8 ] = nz;

			} else {

				scope.normalArray[ c + 0 ] = norm[ o1 + 0 ];
				scope.normalArray[ c + 1 ] = norm[ o1 + 1 ];
				scope.normalArray[ c + 2 ] = norm[ o1 + 2 ];

				scope.normalArray[ c + 3 ] = norm[ o2 + 0 ];
				scope.normalArray[ c + 4 ] = norm[ o2 + 1 ];
				scope.normalArray[ c + 5 ] = norm[ o2 + 2 ];

				scope.normalArray[ c + 6 ] = norm[ o3 + 0 ];
				scope.normalArray[ c + 7 ] = norm[ o3 + 1 ];
				scope.normalArray[ c + 8 ] = norm[ o3 + 2 ];

			}

			// uvs

			if ( scope.enableUvs ) {

				const d = scope.count * 2;

				scope.uvArray[ d + 0 ] = pos[ o1 + 0 ];
				scope.uvArray[ d + 1 ] = pos[ o1 + 2 ];

				scope.uvArray[ d + 2 ] = pos[ o2 + 0 ];
				scope.uvArray[ d + 3 ] = pos[ o2 + 2 ];

				scope.uvArray[ d + 4 ] = pos[ o3 + 0 ];
				scope.uvArray[ d + 5 ] = pos[ o3 + 2 ];

			}

			// colors

			if ( scope.enableColors ) {

				scope.colorArray[ c + 0 ] = colors[ o1 + 0 ];
				scope.colorArray[ c + 1 ] = colors[ o1 + 1 ];
				scope.colorArray[ c + 2 ] = colors[ o1 + 2 ];

				scope.colorArray[ c + 3 ] = colors[ o2 + 0 ];
				scope.colorArray[ c + 4 ] = colors[ o2 + 1 ];
				scope.colorArray[ c + 5 ] = colors[ o2 + 2 ];

				scope.colorArray[ c + 6 ] = colors[ o3 + 0 ];
				scope.colorArray[ c + 7 ] = colors[ o3 + 1 ];
				scope.colorArray[ c + 8 ] = colors[ o3 + 2 ];

			}

			scope.count += 3;

		}

		/////////////////////////////////////
		// Metaballs
		/////////////////////////////////////

		// Adds a reciprocal ball (nice and blobby) that, to be fast, fades to zero after
		// a fixed distance, determined by strength and subtract.

		this.addBall = function ( ballx, bally, ballz, strength, subtract, colors ) {

			const sign = Math.sign( strength );
			strength = Math.abs( strength );
			const userDefineColor = ! ( colors === undefined || colors === null );
			let ballColor = new Color( ballx, bally, ballz );

			if ( userDefineColor ) {

				try {

					ballColor =
						colors instanceof Color
							? colors
