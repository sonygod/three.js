// Ported from Stefan Gustavson's java implementation
// http://staffwww.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf
// Read Stefan's excellent paper for details on how this code works.
//
// Sean McCullough banksean@gmail.com
//
// Added 4D noise

/**
 * You can pass in a random number generator object if you like.
 * It is assumed to have a random() method.
 */
class SimplexNoise {

	public var grad3:Array<Array<Float>>;
	public var grad4:Array<Array<Float>>;
	public var p:Array<Int>;
	public var perm:Array<Int>;
	public var simplex:Array<Array<Int>>;

	public function new(r:Random = Math) {

		this.grad3 = [
			[ 1, 1, 0 ], [ - 1, 1, 0 ], [ 1, - 1, 0 ], [ - 1, - 1, 0 ],
			[ 1, 0, 1 ], [ - 1, 0, 1 ], [ 1, 0, - 1 ], [ - 1, 0, - 1 ],
			[ 0, 1, 1 ], [ 0, - 1, 1 ], [ 0, 1, - 1 ], [ 0, - 1, - 1 ]
		];

		this.grad4 = [
			[ 0, 1, 1, 1 ], [ 0, 1, 1, - 1 ], [ 0, 1, - 1, 1 ], [ 0, 1, - 1, - 1 ],
			[ 0, - 1, 1, 1 ], [ 0, - 1, 1, - 1 ], [ 0, - 1, - 1, 1 ], [ 0, - 1, - 1, - 1 ],
			[ 1, 0, 1, 1 ], [ 1, 0, 1, - 1 ], [ 1, 0, - 1, 1 ], [ 1, 0, - 1, - 1 ],
			[ - 1, 0, 1, 1 ], [ - 1, 0, 1, - 1 ], [ - 1, 0, - 1, 1 ], [ - 1, 0, - 1, - 1 ],
			[ 1, 1, 0, 1 ], [ 1, 1, 0, - 1 ], [ 1, - 1, 0, 1 ], [ 1, - 1, 0, - 1 ],
			[ - 1, 1, 0, 1 ], [ - 1, 1, 0, - 1 ], [ - 1, - 1, 0, 1 ], [ - 1, - 1, 0, - 1 ],
			[ 1, 1, 1, 0 ], [ 1, 1, - 1, 0 ], [ 1, - 1, 1, 0 ], [ 1, - 1, - 1, 0 ],
			[ - 1, 1, 1, 0 ], [ - 1, 1, - 1, 0 ], [ - 1, - 1, 1, 0 ], [ - 1, - 1, - 1, 0 ]
		];

		this.p = new Array<Int>(256);

		for (i in 0...256) {

			this.p[i] = Std.int(r.random() * 256);

		}

		// To remove the need for index wrapping, double the permutation table length
		this.perm = new Array<Int>(512);

		for (i in 0...512) {

			this.perm[i] = this.p[i & 255];

		}

		// A lookup table to traverse the simplex around a given point in 4D.
		// Details can be found where this table is used, in the 4D noise method.
		this.simplex = [
			[ 0, 1, 2, 3 ], [ 0, 1, 3, 2 ], [ 0, 0, 0, 0 ], [ 0, 2, 3, 1 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 1, 2, 3, 0 ],
			[ 0, 2, 1, 3 ], [ 0, 0, 0, 0 ], [ 0, 3, 1, 2 ], [ 0, 3, 2, 1 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 1, 3, 2, 0 ],
			[ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ],
			[ 1, 2, 0, 3 ], [ 0, 0, 0, 0 ], [ 1, 3, 0, 2 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 2, 3, 0, 1 ], [ 2, 3, 1, 0 ],
			[ 1, 0, 2, 3 ], [ 1, 0, 3, 2 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 2, 0, 3, 1 ], [ 0, 0, 0, 0 ], [ 2, 1, 3, 0 ],
			[ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ],
			[ 2, 0, 1, 3 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 3, 0, 1, 2 ], [ 3, 0, 2, 1 ], [ 0, 0, 0, 0 ], [ 3, 1, 2, 0 ],
			[ 2, 1, 0, 3 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 3, 1, 0, 2 ], [ 0, 0, 0, 0 ], [ 3, 2, 0, 1 ], [ 3, 2, 1, 0 ]
		];

	}

	public function dot(g:Array<Float>, x:Float, y:Float):Float {

		return g[0] * x + g[1] * y;

	}

	public function dot3(g:Array<Float>, x:Float, y:Float, z:Float):Float {

		return g[0] * x + g[1] * y + g[2] * z;

	}

	public function dot4(g:Array<Float>, x:Float, y:Float, z:Float, w:Float):Float {

		return g[0] * x + g[1] * y + g[2] * z + g[3] * w;

	}

	public function noise(xin:Float, yin:Float):Float {

		var n0:Float; // Noise contributions from the three corners
		var n1:Float;
		var n2:Float;
		// Skew the input space to determine which simplex cell we're in
		const F2:Float = 0.5 * (Math.sqrt(3.0) - 1.0);
		const s:Float = (xin + yin) * F2; // Hairy factor for 2D
		const i:Int = Math.floor(xin + s);
		const j:Int = Math.floor(yin + s);
		const G2:Float = (3.0 - Math.sqrt(3.0)) / 6.0;
		const t:Float = (i + j) * G2;
		const X0:Float = i - t; // Unskew the cell origin back to (x,y) space
		const Y0:Float = j - t;
		const x0:Float = xin - X0; // The x,y distances from the cell origin
		const y0:Float = yin - Y0;

		// For the 2D case, the simplex shape is an equilateral triangle.
		// Determine which simplex we are in.
		var i1:Int; // Offsets for second (middle) corner of simplex in (i,j) coords

		var j1:Int;
		if (x0 > y0) {

			i1 = 1; j1 = 0;

			// lower triangle, XY order: (0,0)->(1,0)->(1,1)

		}	else {

			i1 = 0; j1 = 1;

		} // upper triangle, YX order: (0,0)->(0,1)->(1,1)

		// A step of (1,0) in (i,j) means a step of (1-c,-c) in (x,y), and
		// a step of (0,1) in (i,j) means a step of (-c,1-c) in (x,y), where
		// c = (3-sqrt(3))/6
		const x1:Float = x0 - i1 + G2; // Offsets for middle corner in (x,y) unskewed coords
		const y1:Float = y0 - j1 + G2;
		const x2:Float = x0 - 1.0 + 2.0 * G2; // Offsets for last corner in (x,y) unskewed coords
		const y2:Float = y0 - 1.0 + 2.0 * G2;
		// Work out the hashed gradient indices of the three simplex corners
		const ii:Int = i & 255;
		const jj:Int = j & 255;
		const gi0:Int = this.perm[ii + this.perm[jj]] % 12;
		const gi1:Int = this.perm[ii + i1 + this.perm[jj + j1]] % 12;
		const gi2:Int = this.perm[ii + 1 + this.perm[jj + 1]] % 12;
		// Calculate the contribution from the three corners
		var t0:Float = 0.5 - x0 * x0 - y0 * y0;
		if (t0 < 0) n0 = 0.0;
		else {

			t0 *= t0;
			n0 = t0 * t0 * this.dot(this.grad3[gi0], x0, y0); // (x,y) of grad3 used for 2D gradient

		}

		var t1:Float = 0.5 - x1 * x1 - y1 * y1;
		if (t1 < 0) n1 = 0.0;
		else {

			t1 *= t1;
			n1 = t1 * t1 * this.dot(this.grad3[gi1], x1, y1);

		}

		var t2:Float = 0.5 - x2 * x2 - y2 * y2;
		if (t2 < 0) n2 = 0.0;
		else {

			t2 *= t2;
			n2 = t2 * t2 * this.dot(this.grad3[gi2], x2, y2);

		}

		// Add contributions from each corner to get the final noise value.
		// The result is scaled to return values in the interval [-1,1].
		return 70.0 * (n0 + n1 + n2);

	}

	// 3D simplex noise
	public function noise3d(xin:Float, yin:Float, zin:Float):Float {

		var n0:Float; // Noise contributions from the four corners
		var n1:Float;
		var n2:Float;
		var n3:Float;
		// Skew the input space to determine which simplex cell we're in
		const F3:Float = 1.0 / 3.0;
		const s:Float = (xin + yin + zin) * F3; // Very nice and simple skew factor for 3D
		const i:Int = Math.floor(xin + s);
		const j:Int = Math.floor(yin + s);
		const k:Int = Math.floor(zin + s);
		const G3:Float = 1.0 / 6.0; // Very nice and simple unskew factor, too
		const t:Float = (i + j + k) * G3;
		const X0:Float = i - t; // Unskew the cell origin back to (x,y,z) space
		const Y0:Float = j - t;
		const Z0:Float = k - t;
		const x0:Float = xin - X0; // The x,y,z distances from the cell origin
		const y0:Float = yin - Y0;
		const z0:Float = zin - Z0;

		// For the 3D case, the simplex shape is a slightly irregular tetrahedron.
		// Determine which simplex we are in.
		var i1:Int; // Offsets for second corner of simplex in (i,j,k) coords

		var j1:Int;
		var k1:Int;
		var i2:Int; // Offsets for third corner of simplex in (i,j,k) coords
		var j2:Int;
		var k2:Int;
		if (x0 >= y0) {

			if (y0 >= z0) {

				i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 1; k2 = 0;

				// X Y Z order

			} else if (x0 >= z0) {

				i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 0; k2 = 1;

				// X Z Y order

			} else {

				i1 = 0; j1 = 0; k1 = 1; i2 = 1; j2 = 0; k2 = 1;

			} // Z X Y order

		} else { // x0<y0

			if (y0 < z0) {

				i1 = 0; j1 = 0; k1 = 1; i2 = 0; j2 = 1; k2 = 1;

				// Z Y X order

			} else if (x0 < z0) {

				i1 = 0; j1 = 1; k1 = 0; i2 = 0; j2 = 1; k2 = 1;

				// Y Z X order

			} else {

				i1 = 0; j1 = 1; k1 = 0; i2 = 1; j2 = 1; k2 = 0;

			} // Y X Z order

		}

		// A step of (1,0,0) in (i,j,k) means a step of (1-c,-c,-c) in (x,y,z),
		// a step of (0,1,0) in (i,j,k) means a step of (-c,1-c,-c) in (x,y,z), and
		// a step of (0,0,1) in (i,j,k) means a step of (-c,-c,1-c) in (x,y,z), where
		// c = 1/6.
		const x1:Float = x0 - i1 + G3; // Offsets for second corner in (x,y,z) coords
		const y1:Float = y0 - j1 + G3;
		const z1:Float = z0 - k1 + G3;
		const x2:Float = x0 - i2 + 2.0 * G3; // Offsets for third corner in (x,y,z) coords
		const y2:Float = y0 - j2 + 2.0 * G3;
		const z2:Float = z0 - k2 + 2.0 * G3;
		const x3:Float = x0 - 1.0 + 3.0 * G3; // Offsets for last corner in (x,y,z) coords
		const y3:Float = y0 - 1.0 + 3.0 * G3;
		const z3:Float = z0 - 1.0 + 3.0 * G3;
		// Work out the hashed gradient indices of the four simplex corners
		const ii:Int = i & 255;
		const jj:Int = j & 255;
		const kk:Int = k & 255;
		const gi0:Int = this.perm[ii + this.perm[jj + this.perm[kk]]] % 12;
		const gi1:Int = this.perm[ii + i1 + this.perm[jj + j1 + this.perm[kk + k1]]] % 12;
		const gi2:Int = this.perm[ii + i2 + this.perm[jj + j2 + this.perm[kk + k2]]] % 12;
		const gi3:Int = this.perm[ii + 1 + this.perm[jj + 1 + this.perm[kk + 1]]] % 12;
		// Calculate the contribution from the four corners
		var t0:Float = 0.6 - x0 * x0 - y0 * y0 - z0 * z0;
		if (t0 < 0) n0 = 0.0;
		else {

			t0 *= t0;
			n0 = t0 * t0 * this.dot3(this.grad3[gi0], x0, y0, z0);

		}

		var t1:Float = 0.6 - x1 * x1 - y1 * y1 - z1 * z1;
		if (t1 < 0) n1 = 0.0;
		else {

			t1 *= t1;
			n1 = t1 * t1 * this.dot3(this.grad3[gi1], x1, y1, z1);

		}

		var t2:Float = 0.6 - x2 * x2 - y2 * y2 - z2 * z2;
		if (t2 < 0) n2 = 0.0;
		else {

			t2 *= t2;
			n2 = t2 * t2 * this.dot3(this.grad3[gi2], x2, y2, z2);

		}

		var t3:Float = 0.6 - x3 * x3 - y3 * y3 - z3 * z3;
		if (t3 < 0) n3 = 0.0;
		else {

			t3 *= t3;
			n3 = t3 * t3 * this.dot3(this.grad3[gi3], x3, y3, z3);

		}

		// Add contributions from each corner to get the final noise value.
		// The result is scaled to stay just inside [-1,1]
		return 32.0 * (n0 + n1 + n2 + n3);

	}

	// 4D simplex noise
	public function noise4d(x:Float, y:Float, z:Float, w:Float):Float {

		// For faster and easier lookups
		const grad4:Array<Array<Float>> = this.grad4;
		const simplex:Array<Array<Int>> = this.simplex;
		const perm:Array<Int> = this.perm;

		// The skewing and unskewing factors are hairy again for the 4D case
		const F4:Float = (Math.sqrt(5.0) - 1.0) / 4.0;
		const G4:Float = (5.0 - Math.sqrt(5.0)) / 20.0;
		var n0:Float; // Noise contributions from the five corners
		var n1:Float;
		var n2:Float;
		var n3:Float;
		var n4:Float;
		// Skew the (x,y,z,w) space to determine which cell of 24 simplices we're in
		const s:Float = (x + y + z + w) * F4; // Factor for 4D skewing
		const i:Int = Math.floor(x + s);
		const j:Int = Math.floor(y + s);
		const k:Int = Math.floor(z + s);
		const l:Int = Math.floor(w + s);
		const t:Float = (i + j + k + l) * G4; // Factor for 4D unskewing
		const X0:Float = i - t; // Unskew the cell origin back to (x,y,z,w) space
		const Y0:Float = j - t;
		const Z0:Float = k - t;
		const W0:Float = l - t;
		const x0:Float = x - X0; // The x,y,z,w distances from the cell origin
		const y0:Float = y - Y0;
		const z0:Float = z - Z0;
		const w0:Float = w - W0;

		// For the 4D case, the simplex is a 4D shape I won't even try to describe.
		// To find out which of the 24 possible simplices we're in, we need to
		// determine the magnitude ordering of x0, y0, z0 and w0.
		// The method below is a good way of finding the ordering of x,y,z,w and
		// then find the correct traversal order for the simplex we’re in.
		// First, six pair-wise comparisons are performed between each possible pair
		// of the four coordinates, and the results are used to add up binary bits
		// for an integer index.
		const c1:Int = (x0 > y0) ? 32 : 0;
		const c2:Int = (x0 > z0) ? 16 : 0;
		const c3:Int = (y0 > z0) ? 8 : 0;
		const c4:Int = (x0 > w0) ? 4 : 0;
		const c5:Int = (y0 > w0) ? 2 : 0;
		const c6:Int = (z0 > w0) ? 1 : 0;
		const c:Int = c1 + c2 + c3 + c4 + c5 + c6;

		// simplex[c] is a 4-vector with the numbers 0, 1, 2 and 3 in some order.
		// Many values of c will never occur, since e.g. x>y>z>w makes x<z, y<w and x<w
		// impossible. Only the 24 indices which have non-zero entries make any sense.
		// We use a thresholding to set the coordinates in turn from the largest magnitude.
		// The number 3 in the "simplex" array is at the position of the largest coordinate.
		const i1:Int = simplex[c][0] >= 3 ? 1 : 0;
		const j1:Int = simplex[c][1] >= 3 ? 1 : 0;
		const k1:Int = simplex[c][2] >= 3 ? 1 : 0;
		const l1:Int = simplex[c][3] >= 3 ? 1 : 0;
		// The number 2 in the "simplex" array is at the second largest coordinate.
		const i2:Int = simplex[c][0] >= 2 ? 1 : 0;
		const j2:Int = simplex[c][1] >= 2 ? 1 : 0;
		const k2:Int = simplex[c][2] >= 2 ? 1 : 0;
		const l2:Int = simplex[c][3] >= 2 ? 1 : 0;
		// The number 1 in the "simplex" array is at the second smallest coordinate.
		const i3:Int = simplex[c][0] >= 1 ? 1 : 0;
		const j3:Int = simplex[c][1] >= 1 ? 1 : 0;
		const k3:Int = simplex[c][2] >= 1 ? 1 : 0;
		const l3:Int = simplex[c][3] >= 1 ? 1 : 0;
		// The fifth corner has all coordinate offsets = 1, so no need to look that up.
		const x1:Float = x0 - i1 + G4; // Offsets for second corner in (x,y,z,w) coords
		const y1:Float = y0 - j1 + G4;
		const z1:Float = z0 - k1 + G4;
		const w1:Float = w0 - l1 + G4;
		const x2:Float = x0 - i2 + 2.0 * G4; // Offsets for third corner in (x,y,z,w) coords
		const y2:Float = y0 - j2 + 2.0 * G4;
		const z2:Float = z0 - k2 + 2.0 * G4;
		const w2:Float = w0 - l2 + 2.0 * G4;
		const x3:Float = x0 - i3 + 3.0 * G4; // Offsets for fourth corner in (x,y,z,w) coords
		const y3:Float = y0 - j3 + 3.0 * G4;
		const z3:Float = z0 - k3 + 3.0 * G4;
		const w3:Float = w0 - l3 + 3.0 * G4;
		const x4:Float = x0 - 1.0 + 4.0 * G4; // Offsets for last corner in (x,y,z,w) coords
		const y4:Float = y0 - 1.0 + 4.0 * G4;
		const z4:Float = z0 - 1.0 + 4.0 * G4;
		const w4:Float = w0 - 1.0 + 4.0 * G4;
		// Work out the hashed gradient indices of the five simplex corners
		const ii:Int = i & 255;
		const jj:Int = j & 255;
		const kk:Int = k & 255;
		const ll:Int = l & 255;
		const gi0:Int = perm[ii + perm[jj + perm[kk + perm[ll]]]] % 32;
		const gi1:Int = perm[ii + i1 + perm[jj + j1 + perm[kk + k1 + perm[ll + l1]]]] % 32;
		const gi2:Int = perm[ii + i2 + perm[jj + j2 + perm[kk + k2 + perm[ll + l2]]]] % 32;
		const gi3:Int = perm[ii + i3 + perm[jj + j3 + perm[kk + k3 + perm[ll + l3]]]] % 32;
		const gi4:Int = perm[ii + 1 + perm[jj + 1 + perm[kk + 1 + perm[ll + 1]]]] % 32;
		// Calculate the contribution from the five corners
		var t0:Float = 0.6 - x0 * x0 - y0 * y0 - z0 * z0 - w0 * w0;
		if (t0 < 0) n0 = 0.0;
		else {

			t0 *= t0;
			n0 = t0 * t0 * this.dot4(grad4[gi0], x0, y0, z0, w0);

		}

		var t1:Float = 0.6 - x1 * x1 - y1 * y1 - z1 * z1 - w1 * w1;
		if (t1 < 0) n1 = 0.0;
		else {

			t1 *= t1;
			n1 = t1 * t1 * this.dot4(grad4[gi1], x1, y1, z1, w1);

		}

		var t2:Float = 0.6 - x2 * x2 - y2 * y2 - z2 * z2 - w2 * w2;
		if (t2 < 0) n2 = 0.0;
		else {

			t2 *= t2;
			n2 = t2 * t2 * this.dot4(grad4[gi2], x2, y2, z2, w2);

		}

		var t3:Float = 0.6 - x3 * x3 - y3 * y3 - z3 * z3 - w3 * w3;
		if (t3 < 0) n3 = 0.0;
		else {

			t3 *= t3;
			n3 = t3 * t3 * this.dot4(grad4[gi3], x3, y3, z3, w3);

		}

		var t4:Float = 0.6 - x4 * x4 - y4 * y4 - z4 * z4 - w4 * w4;
		if (t4 < 0) n4 = 0.0;
		else {

			t4 *= t4;
			n4 = t4 * t4 * this.dot4(grad4[gi4], x4, y4, z4, w4);

		}

		// Sum up and scale the result to cover the range [-1,1]
		return 27.0 * (n0 + n1 + n2 + n3 + n4);

	}

}