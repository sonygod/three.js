import js.Math;

class SimplexNoise {
    private var grad3: Array<Array<Float>>;
    private var grad4: Array<Array<Float>>;
    private var p: Array<Int>;
    private var perm: Array<Int>;
    private var simplex: Array<Array<Int>>;

    public function new(r: js.Math = js.Math) {
        this.grad3 = [[ 1, 1, 0 ], [ -1, 1, 0 ], [ 1, -1, 0 ], [ -1, -1, 0 ],
            [ 1, 0, 1 ], [ -1, 0, 1 ], [ 1, 0, -1 ], [ -1, 0, -1 ],
            [ 0, 1, 1 ], [ 0, -1, 1 ], [ 0, 1, -1 ], [ 0, -1, -1 ]];

        this.grad4 = [[ 0, 1, 1, 1 ], [ 0, 1, 1, -1 ], [ 0, 1, -1, 1 ], [ 0, 1, -1, -1 ],
            [ 0, -1, 1, 1 ], [ 0, -1, 1, -1 ], [ 0, -1, -1, 1 ], [ 0, -1, -1, -1 ],
            [ 1, 0, 1, 1 ], [ 1, 0, 1, -1 ], [ 1, 0, -1, 1 ], [ 1, 0, -1, -1 ],
            [ -1, 0, 1, 1 ], [ -1, 0, 1, -1 ], [ -1, 0, -1, 1 ], [ -1, 0, -1, -1 ],
            [ 1, 1, 0, 1 ], [ 1, 1, 0, -1 ], [ 1, -1, 0, 1 ], [ 1, -1, 0, -1 ],
            [ -1, 1, 0, 1 ], [ -1, 1, 0, -1 ], [ -1, -1, 0, 1 ], [ -1, -1, 0, -1 ],
            [ 1, 1, 1, 0 ], [ 1, 1, -1, 0 ], [ 1, -1, 1, 0 ], [ 1, -1, -1, 0 ],
            [ -1, 1, 1, 0 ], [ -1, 1, -1, 0 ], [ -1, -1, 1, 0 ], [ -1, -1, -1, 0 ]];

        this.p = [];
        for (i in 0...256) {
            this.p[i] = Math.floor(r.random() * 256);
        }

        this.perm = [];
        for (i in 0...512) {
            this.perm[i] = this.p[i & 255];
        }

        this.simplex = [
            [0,1,2,3],[0,1,3,2],[0,0,0,0],[0,2,3,1],[0,0,0,0],[0,0,0,0],[0,0,0,0],[1,2,3,0],
            [0,2,1,3],[0,0,0,0],[0,3,1,2],[0,3,2,1],[0,0,0,0],[0,0,0,0],[0,0,0,0],[1,3,2,0],
            [0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],
            [1,2,0,3],[0,0,0,0],[1,3,0,2],[0,0,0,0],[0,0,0,0],[0,0,0,0],[2,3,0,1],[2,3,1,0],
            [1,0,2,3],[1,0,3,2],[0,0,0,0],[0,0,0,0],[0,0,0,0],[2,0,3,1],[0,0,0,0],[2,1,3,0],
            [0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0],
            [2,0,1,3],[0,0,0,0],[0,0,0,0],[0,0,0,0],[3,0,1,2],[3,0,2,1],[0,0,0,0],[3,1,2,0],
            [2,1,0,3],[0,0,0,0],[0,0,0,0],[0,0,0,0],[3,1,0,2],[0,0,0,0],[3,2,0,1],[3,2,1,0]];
    }

    private function dot(g: Array<Float>, x: Float, y: Float): Float {
        return g[0] * x + g[1] * y;
    }

    private function dot3(g: Array<Float>, x: Float, y: Float, z: Float): Float {
        return g[0] * x + g[1] * y + g[2] * z;
    }

    private function dot4(g: Array<Float>, x: Float, y: Float, z: Float, w: Float): Float {
        return g[0] * x + g[1] * y + g[2] * z + g[3] * w;
    }

    public function noise(xin: Float, yin: Float): Float {
        var F2: Float = 0.5 * (Math.sqrt(3.0) - 1.0);
        var s: Float = (xin + yin) * F2;
        var i: Int = Math.floor(xin + s);
        var j: Int = Math.floor(yin + s);
        var G2: Float = (3.0 - Math.sqrt(3.0)) / 6.0;
        var t: Float = (i + j) * G2;
        var X0: Float = i - t;
        var Y0: Float = j - t;
        var x0: Float = xin - X0;
        var y0: Float = yin - Y0;

        var i1: Int;
        var j1: Int;
        if (x0 > y0) {
            i1 = 1; j1 = 0;
        } else {
            i1 = 0; j1 = 1;
        }

        var x1: Float = x0 - i1 + G2;
        var y1: Float = y0 - j1 + G2;
        var x2: Float = x0 - 1.0 + 2.0 * G2;
        var y2: Float = y0 - 1.0 + 2.0 * G2;

        var ii: Int = i & 255;
        var jj: Int = j & 255;
        var gi0: Int = this.perm[ii + this.perm[jj]] % 12;
        var gi1: Int = this.perm[ii + i1 + this.perm[jj + j1]] % 12;
        var gi2: Int = this.perm[ii + 1 + this.perm[jj + 1]] % 12;

        var t0: Float = 0.5 - x0 * x0 - y0 * y0;
        var n0: Float = t0 < 0 ? 0.0 : t0 * t0 * this.dot(this.grad3[gi0], x0, y0);

        var t1: Float = 0.5 - x1 * x1 - y1 * y1;
        var n1: Float = t1 < 0 ? 0.0 : t1 * t1 * this.dot(this.grad3[gi1], x1, y1);

        var t2: Float = 0.5 - x2 * x2 - y2 * y2;
        var n2: Float = t2 < 0 ? 0.0 : t2 * t2 * this.dot(this.grad3[gi2], x2, y2);

        return 70.0 * (n0 + n1 + n2);
    }

    public function noise3d(xin: Float, yin: Float, zin: Float): Float {
        var F3: Float = 1.0 / 3.0;
        var s: Float = (xin + yin + zin) * F3;
        var i: Int = Math.floor(xin + s);
        var j: Int = Math.floor(yin + s);
        var k: Int = Math.floor(zin + s);
        var G3: Float = 1.0 / 6.0;
        var t: Float = (i + j + k) * G3;
        var X0: Float = i - t;
        var Y0: Float = j - t;
        var Z0: Float = k - t;
        var x0: Float = xin - X0;
        var y0: Float = yin - Y0;
        var z0: Float = zin - Z0;

        var i1: Int;
        var j1: Int;
        var k1: Int;
        var i2: Int;
        var j2: Int;
        var k2: Int;
        if (x0 >= y0) {
            if (y0 >= z0) {
                i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 1; k2 = 0;
            } else if (x0 >= z0) {
                i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 0; k2 = 1;
            } else {
                i1 = 0; j1 = 0; k1 = 1; i2 = 1; j2 = 0; k2 = 1;
            }
        } else {
            if (y0 < z0) {
                i1 = 0; j1 = 0; k1 = 1; i2 = 0; j2 = 1; k2 = 1;
            } else if (x0 < z0) {
                i1 = 0; j1 = 1; k1 = 0; i2 = 0; j2 = 1; k2 = 1;
            } else {
                i1 = 0; j1 = 1; k1 = 0; i2 = 1; j2 = 1; k2 = 0;
            }
        }

        var x1: Float = x0 - i1 + G3;
        var y1: Float = y0 - j1 + G3;
        var z1: Float = z0 - k1 + G3;
        var x2: Float = x0 - i2 + 2.0 * G3;
        var y2: Float = y0 - j2 + 2.0 * G3;
        var z2: Float = z0 - k2 + 2.0 * G3;
        var x3: Float = x0 - 1.0 + 3.0 * G3;
        var y3: Float = y0 - 1.0 + 3.0 * G3;
        var z3: Float = z0 - 1.0 + 3.0 * G3;

        var ii: Int = i & 255;
        var jj: Int = j & 255;
        var kk: Int = k & 255;
        var gi0: Int = this.perm[ii + this.perm[jj + this.perm[kk]]] % 12;
        var gi1: Int = this.perm[ii + i1 + this.perm[jj + j1 + this.perm[kk + k1]]] % 12;
        var gi2: Int = this.perm[ii + i2 + this.perm[jj + j2 + this.perm[kk + k2]]] % 12;
        var gi3: Int = this.perm[ii + 1 + this.perm[jj + 1 + this.perm[kk + 1]]] % 12;

        var t0: Float = 0.6 - x0 * x0 - y0 * y0 - z0 * z0;
        var n0: Float = t0 < 0 ? 0.0 : t0 * t0 * this.dot3(this.grad3[gi0], x0, y0, z0);

        var t1: Float = 0.6 - x1 * x1 - y1 * y1 - z1 * z1;
        var n1: Float = t1 < 0 ? 0.0 : t1 * t1 * this.dot3(this.grad3[gi1], x1, y1, z1);

        var t2: Float = 0.6 - x2 * x2 - y2 * y2 - z2 * z2;
        var n2: Float = t2 < 0 ? 0.0 : t2 * t2 * this.dot3(this.grad3[gi2], x2, y2, z2);

        var t3: Float = 0.6 - x3 * x3 - y3 * y3 - z3 * z3;
        var n3: Float = t3 < 0 ? 0.0 : t3 * t3 * this.dot3(this.grad3[gi3], x3, y3, z3);

        return 32.0 * (n0 + n1 + n2 + n3);
    }

    public function noise4d(x: Float, y: Float, z: Float, w: Float): Float {
        var F4: Float = (Math.sqrt(5.0) - 1.0) / 4.0;
        var G4: Float = (5.0 - Math.sqrt(5.0)) / 20.0;
        var s: Float = (x + y + z + w) * F4;
        var i: Int = Math.floor(x + s);
        var j: Int = Math.floor(y + s);
        var k: Int = Math.floor(z + s);
        var l: Int = Math.floor(w + s);
        var t: Float = (i + j + k + l) * G4;
        var X0: Float = i - t;
        var Y0: Float = j - t;
        var Z0: Float = k - t;
        var W0: Float = l - t;
        var x0: Float = x - X0;
        var y0: Float = y - Y0;
        var z0: Float = z - Z0;
        var w0: Float = w - W0;

        var c1: Int = (x0 > y0) ? 32 : 0;
        var c2: Int = (x0 > z0) ? 16 : 0;
        var c3: Int = (y0 > z0) ? 8 : 0;
        var c4: Int = (x0 > w0) ? 4 : 0;
        var c5: Int = (y0 > w0) ? 2 : 0;
        var c6: Int = (z0 > w0) ? 1 : 0;
        var c: Int = c1 + c2 + c3 + c4 + c5 + c6;

        var i1: Int = this.simplex[c][0] >= 3 ? 1 : 0;
        var j1: Int = this.simplex[c][1] >= 3 ? 1 : 0;
        var k1: Int = this.simplex[c][2] >= 3 ? 1 : 0;
        var l1: Int = this.simplex[c][3] >= 3 ? 1 : 0;
        var i2: Int = this.simplex[c][0] >= 2 ? 1 : 0;
        var j2: Int = this.simplex[c][1] >= 2 ? 1 : 0;
        var k2: Int = this.simplex[c][2] >= 2 ? 1 : 0;
        var l2: Int = this.simplex[c][3] >= 2 ? 1 : 0;
        var i3: Int = this.simplex[c][0] >= 1 ? 1 : 0;
        var j3: Int = this.simplex[c][1] >= 1 ? 1 : 0;
        var k3: Int = this.simplex[c][2] >= 1 ? 1 : 0;
        var l3: Int = this.simplex[c][3] >= 1 ? 1 : 0;

        var x1: Float = x0 - i1 + G4;
        var y1: Float = y0 - j1 + G4;
        var z1: Float = z0 - k1 + G4;
        var w1: Float = w0 - l1 + G4;
        var x2: Float = x0 - i2 + 2.0 * G4;
        var y2: Float = y0 - j2 + 2.0 * G4;
        var z2: Float = z0 - k2 + 2.0 * G4;
        var w2: Float = w0 - l2 + 2.0 * G4;
        var x3: Float = x0 - i3 + 3.0 * G4;
        var y3: Float = y0 - j3 + 3.0 * G4;
        var z3: Float = z0 - k3 + 3.0 * G4;
        var w3: Float = w0 - l3 + 3.0 * G4;
        var x4: Float = x0 - 1.0 + 4.0 * G4;
        var y4: Float = y0 - 1.0 + 4.0 * G4;
        var z4: Float = z0 - 1.0 + 4.0 * G4;
        var w4: Float = w0 - 1.0 + 4.0 * G4;

        var ii: Int = i & 255;
        var jj: Int = j & 255;
        var kk: Int = k & 255;
        var ll: Int = l & 255;
        var gi0: Int = this.perm[ii + this.perm[jj + this.perm[kk + this.perm[ll]]]] % 32;
        var gi1: Int = this.perm[ii + i1 + this.perm[jj + j1 + this.perm[kk + k1 + this.perm[ll + l1]]]] % 32;
        var gi2: Int = this.perm[ii + i2 + this.perm[jj + j2 + this.perm[kk + k2 + this.perm[ll + l2]]]] % 32;
        var gi3: Int = this.perm[ii + i3 + this.perm[jj + j3 + this.perm[kk + k3 + this.perm[ll + l3]]]] % 32;
        var gi4: Int = this.perm[ii + 1 + this.perm[jj + 1 + this.perm[kk + 1 + this.perm[ll + 1]]]] % 32;

        var t0: Float = 0.6 - x0 * x0 - y0 * y0 - z0 * z0 - w0 * w0;
        var n0: Float = t0 < 0 ? 0.0 : t0 * t0 * this.dot4(this.grad4[gi0], x0, y0, z0, w0);

        var t1: Float = 0.6 - x1 * x1 - y1 * y1 - z1 * z1 - w1 * w1;
        var n1: Float = t1 < 0 ? 0.0 : t1 * t1 * this.dot4(this.grad4[gi1], x1, y1, z1, w1);

        var t2: Float = 0.6 - x2 * x2 - y2 * y2 - z2 * z2 - w2 * w2;
        var n2: Float = t2 < 0 ? 0.0 : t2 * t2 * this.dot4(this.grad4[gi2], x2, y2, z2, w2);

        var t3: Float = 0.6 - x3 * x3 - y3 * y3 - z3 * z3 - w3 * w3;
        var n3: Float = t3 < 0 ? 0.0 : t3 * t3 * this.dot4(this.grad4[gi3], x3, y3, z3, w3);

        var t4: Float = 0.6 - x4 * x4 - y4 * y4 - z4 * z4 - w4 * w4;
        var n4: Float = t4 < 0 ? 0.0 : t4 * t4 * this.dot4(this.grad4[gi4], x4, y4, z4, w4);

        return 27.0 * (n0 + n1 + n2 + n3 + n4);
    }
}